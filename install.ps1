
Param([parameter(mandatory)][string]$version, $dest="build", $projects="all")

if ( Test-Path "$dest" ) {
  Write-Error "$dest already exists"
  exit 1
}

$timestamp = Get-Date -Format FileDateTime

function Make-Tmp {
  pushd "$PSScriptRoot"
    if ( Test-Path "./.tmp/$timestamp" ) {
      Write-Error "Failed to make temporally directory"
      exit 1
    }
    mkdir "./.tmp/$timestamp"
  popd
  return "$PSScriptRoot/.tmp/$timestamp"
}

function Clear-Tmp {
  rmdir "$PSScriptRoot/.tmp/$timestamp" -Recurse -Force
}

$tmpdir = Make-Tmp()

pushd $PSScriptRoot
  if ( -not (Test-Path install.ps1) ) {
    write-Error "Cannot find install.ps1 itself"
    exit 1
  }
popd

git clone https://github.com/llvm/llvm-project.git "$tmpdir/llvm-project"

pushd "$tmpdir/llvm-project"
  git reset --hard
  git clean -fdx
  git checkout "llvmorg-$version"
  if ($? -ne $True) {
    write-Error "checking-out to version $version (branch `"llvmorg-$version`") was failed!"
    exit 1
  }
popd

mkdir $dest

if ( Test-Path "$dest" ) {
  Write-Error "$dest cannot be used as a destination"
  exit 1
}

pushd $dest
  cp "$tmpdir/llvm-project/llvm/LICENSE.TXT" . -Force

  $stopwatch = [Diagnostics.Stopwatch]::StartNew()

  cmake -GNinja -B. "$PSScriptRoot/.tmp/llvm-project/llvm" -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ "-DLLVM_ENABLE_PROJECTS=$projects" -DLLVM_TARGETS_TO_BUILD=X86 -DCMAKE_BUILD_TYPE=Release
  ninja

  $stopwatch.Stop()
  $elapsedSec = [int]($stopwatch.Elapsed)
  $elapsedMin = [int]($elapsedSec / 60)
  $elapsedHour = [int]($elapsedMin / 60)
  $elapsedSec %= 60
  $elapsedMin %= 60

  echo "build time : $elapsedHour hr $elapsedMin min $elapsedSec sec"
popd

Clear-Tmp()

