
Param([parameter(mandatory)][string]$version, $dest="build")

if ( Test-Path "$dest" ) {
  Write-Error "$dest already exists"
  exit 1
}

pushd $PSScriptRoot
  if ( -not (Test-Path install.ps1) ) {
    exit 1
  }

  if ( -not (Test-Path .tmp/llvm-project) ) {
    git clone https://github.com/llvm/llvm-project.git ./.tmp/llvm-project
  }

  pushd .tmp/llvm-project
    git reset --hard
    git clean -fdx
    git checkout "llvmorg-$version"
    if ($? -ne $True) {
      write-Error "checking-out to version $version (branch `"llvmorg-$version`") was failed!"
      exit 1
    }
  popd
popd

mkdir $dest

pushd $dest
  cp "$PSScriptRoot/.tmp/llvm-project/llvm/LICENSE.TXT" . -Force

  $stopwatch = [Diagnostics.Stopwatch]::StartNew()

  cmake -GNinja -B. "$PSScriptRoot/.tmp/llvm-project/llvm" -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ "-DLLVM_ENABLE_PROJECTS=clang;lld;" -DLLVM_TARGETS_TO_BUILD=X86 -DCMAKE_BUILD_TYPE=Release
  ninja

  $stopwatch.Stop()
  $elapsedSec = [int]($stopwatch.Elapsed)
  $elapsedMin = [int]($elapsedSec / 60)
  $elapsedHour = [int]($elapsedMin / 60)
  $elapsedSec %= 60
  $elapsedMin %= 60

  echo "build time : $elapsedHour hr $elapsedMin min $elapsedSec sec"
popd

