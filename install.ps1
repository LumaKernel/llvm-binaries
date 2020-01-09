
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
  $script:elapsedSec = [int]($stopwatch.Elapsed)
  $script:elapsedMin = [int]($elapsedSec / 60)
  $script:elapsedHour = [int]($elapsedMin / 60)
  $script:elapsedSec %= 60
  $script:elapsedMin %= 60

  echo "build time : $elapsedHour hr $elapsedMin min $elapsedSec sec"
}

$script:Path = $env:Path

function Revert-Env-Path {
  $env:Path = $script:Path
}


$tmpdir = Make-Tmp

pushd $PSScriptRoot
  if ( -not (Test-Path install.ps1) ) {
    Revert-Env-Path
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

  foreach ($target in $tryTargets ) {
    if (Test-Path $target) {
      if ( (Get-Item $target) -isnot [System.IO.DirectoryInfo] ) {
        echo "VS setting file: $target"
        echo "@echo off`ncall `"$target`"`necho %Path%" `
          | Out-String `
          | % { [Text.Encoding]::UTF8.GetBytes($_) } `
          | Set-Content -Path "$tmpdir/setenv.bat" -Encoding Byte

        $env:Path = "$((&"$tmpdir/setenv.bat" -split `n)[-1]);$env:Path"
        if (Get-Command "cl" -ErrorAction SilentlyContinue) { return }
      }
    }
  }

  Revert-Env-Path
  Throw "Not found executable `"cl`""
}

Check-VS-Compiler

git clone https://github.com/llvm/llvm-project.git "$tmpdir/llvm-project"

pushd "$tmpdir/llvm-project"
  git reset --hard
  git clean -fdx
  git checkout "llvmorg-$version"
  if ($? -ne $True) {
    Clear-Tmp
    Revert-Env-Path
    Throw "checking-out to version $version (branch `"llvmorg-$version`") was failed!"
  }
popd

if ( Test-Path $dest ) {
  Clear-Tmp
  Revert-Env-Path
  Throw "$dest cannot be used as a destination"
}

mkdir $dest

pushd $dest
  cp "$tmpdir/llvm-project/llvm/LICENSE.TXT" . -Force

  Timer-Start

  cmake -GNinja "-B." "$tmpdir/llvm-project/llvm" -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl "-DLLVM_ENABLE_PROJECTS=$projects" -DLLVM_TARGETS_TO_BUILD=X86 -DCMAKE_BUILD_TYPE=Release
  if (-not $?) {
    Revert-Env-Path
    Throw "CMake was failed!"
  }
  ninja
  if (-not $?) {
    Revert-Env-Path
    Throw "Ninja was failed!"
  }

  Timer-Stop-Show
popd

Clear-Tmp
Revert-Env-Path

