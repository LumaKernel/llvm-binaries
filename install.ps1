
Param([parameter(mandatory=$true)][string]$version, [switch]$x64)

cd $PSScriptRoot

if (-not Test-Path install.ps1) {
  exit 1
}

if (Test-Path .tmp) {
  rm .tmp -Recurse -Force
  rm * -Exclude install.ps1 -Recurse
}

git clone https://github.com/llvm/llvm-project.git ./.tmp/llvm-project --branch "llvmorg-$version"

cp ./.tmp/llvm-project/llvm/LICENSE.TXT .

$cflags="-m32"
$cxxflags="-m32"
if ($x64 -eq \"64bit\") {
  $cflags="-m64"
  $cxxflags="-m64"
}

cmake -GNinja -B. "./.tmp/llvm/llvm-project/llvm" -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DLLVM_ENABLE_PROJECTS=clang;lld; -DLLVM_TARGETS_TO_BUILD=X86 -DCMAKE_BUILD_TYPE=Release "-DCMAKE_C_FLAGS=$cflags" "-DCMAKE_CXX_FLAGS=$cxxflags"
ninja

