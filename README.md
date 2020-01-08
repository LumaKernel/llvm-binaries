
自分の scoop bucket 用にバイナリを用意．なので Windows の分のバイナリしかないよ


>    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimers in the
      documentation and/or other materials provided with the distribution.
      参考: [llvm9.0.0 ライセンス](http://releases.llvm.org/9.0.0/LICENSE.TXT)


ということなので，`llvm/LICENSE.txt` のコピーさえ忘れなければ大丈夫そう


なお，このREADME，install.ps1 は [WTFPL](http://www.wtfpl.net/) にします．

# ビルド手順

準備

```powershell
scoop install git gcc cmake ninja
```

clone とかはスクリプトがやってくれる．
VSCommunity を(おそらく)必要としないものだが，
`clgan;lld;` しかビルドしない．公式のに近いものをビルドするなら，
VSCommunityを用意してビルドする必要がありそう．
まあ用意してもいいけど，`scoop` で提供された VSCommunity のいいバケットが見つかるまでいいかな，ということで
(ビルドは時間がかかってたいへん)


```powershell
# scoop のパスを一番手前に ぶっこむなら
# $env:Path = "C:\ProgramData\scoop\shims;$env:UserProfile\scoop\shims;$env:Path"

rmdir build -Recurse -Force
./install.ps1 -version 9.0.1 -dest build

# 成功したら build をリリース
```

ビルド目安時間 : 


アーキテクチャのチェック

```bash
# MSYS2 とか WSL で
file ./build/bin/clang-cl.exe
```


32 bit版の gcc を入れたら 32bit 版も手に入るんじゃないかなあおそらく

```powershell
scoop install gcc -a 32bit
```

