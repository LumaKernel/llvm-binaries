
Param(
  [Parameter(mandatory)]
  [string]
  $version,

  [Parameter(mandatory)]
  [ValidateSet("32","64")]
  [String]
  $arch,

  $dest="build",

  $projects="all"
)

if ( Test-Path $dest ) {
  Throw "Path '$dest' already exists"
}

$timestamp = Get-Date -Format FileDateTime

function Make-Tmp {

  &{
    pushd $psscriptroot
      if ( test-path "./.tmp/$timestamp" ) {
        throw "failed to make temporally directory"
      }
      mkdir "./.tmp/$timestamp"
    popd
  } | Out-Null
 
  return "$PSScriptRoot/.tmp/$timestamp"
}

function Clear-Tmp {
  rmdir "$PSScriptRoot/.tmp/$timestamp" -Recurse -Force
}

function Timer-Start {
  $script:stopwatch = [Diagnostics.Stopwatch]::StartNew()
}

function Timer-Stop-Show {
  $script:stopwatch.Stop()
  $elapsedSec = [int]($script:stopwatch.Elapsed.TotalSeconds)
  $elapsedMin = [int]($elapsedSec / 60)
  $elapsedHour = [int]($elapsedMin / 60)
  $elapsedSec %= 60
  $elapsedMin %= 60

  echo "total time : $elapsedHour hr $elapsedMin min $elapsedSec sec"
}


$tmpdir = Make-Tmp

pushd $PSScriptRoot
  if ( -not (Test-Path install.ps1) ) {
    Throw "Cannot find install.ps1 itself"
  }
popd

function Check-VS-Compiler {
  if (Get-Command "cl" -ErrorAction SilentlyContinue) { return }
  $vs_versions = "2019", "2017"

  $tryTargets =
    ($vs_versions | %{
      "C:\Program Files (x86)\Microsoft Visual Studio\$_\Community\VC\Auxiliary\Build\vcvars$arch.bat"
    }) +
    ($vs_versions | %{
      "C:\Program Files\Microsoft Visual Studio\$_\Community\VC\Auxiliary\Build\vcvars$arch.bat"
    })

  foreach ( $target in $tryTargets ) {
    if (Test-Path $target) {
      if ( (Get-Item $target) -isnot [System.IO.DirectoryInfo] ) {
        echo "VS setting file: $target"
        echo $(@(
            "@echo off"
            "call `"$target`""
            "powershell powershell-util\Dump-Env.ps1 -File env.txt"
          ) -join `n) |
          Out-String |
          % { [Text.Encoding]::UTF8.GetBytes($_) } |
          Set-Content -Path "$tmpdir/setenv.bat" -Encoding Byte

        pushd $tmpdir
          ./setenv.bat
        popd

        &"$tmpdir/powershell-util/Revert-Env.ps1" "$tmpdir/env.txt"

        if (Get-Command "cl" -ErrorAction SilentlyContinue) { return }
      }
    }
  }

  Throw "Not found executable `"cl`""
}

try {
  Timer-Start

  git clone https://github.com/LumaKernel/PowerShell-utils.git "$tmpdir/powershell-util"

  git clone https://github.com/llvm/llvm-project.git "$tmpdir/llvm-project"

  $script:env_saved = &"$tmpdir/powershell-util/Dump-Env.ps1"

  Check-VS-Compiler

  pushd "$tmpdir/llvm-project"
    git reset --hard
    git clean -fdx
    git checkout "llvmorg-$version"
    if ($? -ne $True) {
      Clear-Tmp
      Throw "checking-out to version $version (branch `"llvmorg-$version`") was failed!"
    }
  popd

  if ( Test-Path $dest ) {
    Clear-Tmp
    Throw "$dest cannot be used as a destination"
  }

  mkdir $dest

  pushd $dest
    cp "$tmpdir/llvm-project/llvm/LICENSE.TXT" . -Force

    cmake -GNinja "-B." "$tmpdir/llvm-project/llvm" -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl "-DLLVM_ENABLE_PROJECTS=$projects" -DLLVM_TARGETS_TO_BUILD=X86 -DCMAKE_BUILD_TYPE=Release
    if (-not $?) {
      Throw "CMake was failed!"
    }
    ninja
    if (-not $?) {
      Throw "Ninja was failed!"
    }

  popd
  
  Timer-Stop-Show
} finally {
  &"$tmpdir/powershell-util/Revert-Env.ps1" $script:env_saved
}

Clear-Tmp

