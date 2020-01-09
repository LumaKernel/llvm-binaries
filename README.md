
[llvm/llvm-project](https://github.com/llvm/llvm-project) をビルドする

自分の scoop bucket 用にバイナリを用意．なので Windows の分のバイナリしかないよ


>    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimers in the
      documentation and/or other materials provided with the distribution.
      参考: [llvm9.0.0 ライセンス](http://releases.llvm.org/9.0.0/LICENSE.TXT)


ということなので，`llvm/LICENSE.txt` のコピーさえ忘れなければ大丈夫そう


このREADME，install.ps1 は [WTFPL](http://www.wtfpl.net/) にします．

# ビルド手順

準備

```powershell
scoop install git cmake ninja
```

加えて MSVC が必要， [VSCommunity2019](https://docs.microsoft.com/en-us/visualstudio/releases/2019/release-notes-history?view=vs-2019) や [VSCommunity2017](https://docs.microsoft.com/en-us/visualstudio/releases/2019/release-notes-history?view=vs-2019) をそのままインストールすると，勝手にパスを取りに行く．


scoop で入れられるようにしたかったけど，その場合パスを通してあげるようにしたほうがいいのかどうか悩ましくなってしまったので今回は一応…


もし cl コンパイラが見つからないと言われたら，

```powershell
# powershell
cmd /c <MSVCのパス>/Community\VC\Auxiliary\Build\vcvars64.bat && powershell
```

みたいな感じで実行した後で install.ps1 スクリプトをたたけばいい

この公式のパスぶっこみバッチファイルは，そのプロセスでの一時的なもの．


clone とかは install.ps1 スクリプトがやってくれる．

```powershell
# scoop のパスを一番手前に ぶっこむなら
# $env:Path = "C:\ProgramData\scoop\shims;$env:UserProfile\scoop\shims;$env:Path"

rmdir build -Recurse -Force
./install.ps1 -version 9.0.1 -dest build -projects "clang;lld;"

# 成功したら build をリリース
```

ビルド目安時間 : 


アーキテクチャのチェック

```bash
# MSYS2 とか WSL で
file ./build/bin/clang-cl.exe
```


---

[ajkhoury/LLVM-Build-Windows](https://github.com/ajkhoury/LLVM-Build-Windows) も参考になるかもしれない．
MSVCかClang，それとMSYSでビルドするためのバッチらしい?

