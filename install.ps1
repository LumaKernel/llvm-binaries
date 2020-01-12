
Param(
  [Parameter(mandatory)]
  [string]
  $version,

  [Parameter(mandatory)]
  [ValidateSet("32","64")]
  [String]
  $arch,

  $dest="build",

  $projects="all",

  [switch]$indepent
)

if ( Test-Path $dest ) {
  Throw "Path '$dest' already exists"
}

$timestamp = Get-Date -Format FileDateTime

function Make-Tmp {

  &{
    pushd $psscriptroot
      if ( test-path "./.tmp/$timestamp" ) {
        throw "Failed to make temporally directory"
      }
      mkdir "./.tmp/$timestamp"
    popd
  } | Out-Null

  return "$PSScriptRoot/.tmp/$timestamp", "$PSScriptRoot/.tmp/shared"
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


$tmpdir, $shared_tmpdir = Make-Tmp

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
      "C:\Program Files (x86)\Microsoft Visual Studio\$_\Community\VC\Auxiliary\Build\vcvarsx86_amd64.bat"
    })
    # ($vs_versions | %{
    #   "C:\Program Files (x86)\Microsoft Visual Studio\$_\Community\Common7\Tools\VsDevCmd.bat"
    # })

  foreach ( $target in $tryTargets ) {
    if (Test-Path $target) {
      if ( (Get-Item $target) -isnot [System.IO.DirectoryInfo] ) {
        echo "VS setting file: $target"
        echo $(@(
            "@echo off"
            "call `"$target`""
            "powershell powershell-util\Dump-Env.ps1 -File env.txt"
          ) -join "`n") |
          Out-String |
          % { [Text.Encoding]::UTF8.GetBytes($_) } |
          Set-Content -Path "$tmpdir/setenv.bat" -Encoding Byte

        pushd $tmpdir
          ./setenv.bat
        popd

        &"$tmpdir/powershell-util/Revert-Env.ps1" -File "$tmpdir/env.txt"

        if (Get-Command "cl" -ErrorAction SilentlyContinue) { return }
      }
    }
  }

  Clear-Tmp
  Throw "Not found executable `"cl`""
}

try {
  Timer-Start

  git clone https://github.com/LumaKernel/PowerShell-utils.git "$tmpdir/powershell-util"

  if ($indepent) {
    $llvm_dir = "$tmpdir/llvm-project"
  } else {
    $llvm_dir = "$shared_tmpdir/llvm-project"
  }

  if ( -not (Test-Path $llvm_dir) ) {
    git clone https://github.com/llvm/llvm-project.git $llvm_dir
  }

  $script:env_saved = &"$tmpdir/powershell-util/Dump-Env.ps1"

  Check-VS-Compiler

  pushd $llvm_dir
    git reset --hard
    git clean -fdx
    git checkout "llvmorg-$version"
    if ($LASTEXITCODE) {
      Clear-Tmp
      Throw "checking-out to version $version (branch `"llvmorg-$version`") was failed!"
    }
  popd

  if ( Test-Path $dest ) {
    Clear-Tmp
    Throw "$dest cannot be used as a destination"
  }

  mkdir $dest

  $dest_rel = $dest
  $dest = Resolve-Path $dest

  pushd $dest
  try {
    cp "$llvm_dir\llvm\LICENSE.TXT" $dest -Force

    cmake -GNinja "-B." "$llvm_dir\llvm" -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl "-DLLVM_ENABLE_PROJECTS=$projects" -DLLVM_TARGETS_TO_BUILD=X86 -DCMAKE_BUILD_TYPE=Release
    if ($LASTEXITCODE) {
      Throw "CMake was failed!"
    }
    ninja
    if ($LASTEXITCODE) {
      Throw "Ninja was failed!"
    }
  } finally { popd }

  Timer-Stop-Show
} finally {
  if (Test-Path "$tmpdir/powershell-util/Revert-Env.ps1") {
    &"$tmpdir/powershell-util/Revert-Env.ps1" $script:env_saved
  }
}

Clear-Tmp

