
自分の scoop bucket 用にバイナリを用意．なので Windows の分のバイナリしかないよ


>    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimers in the
      documentation and/or other materials provided with the distribution.
      参考: [llvm9.0.0 ライセンス](http://releases.llvm.org/9.0.0/LICENSE.TXT)


ということなので，`llvm/LICENSE.txt` のコピーさえ忘れなければ大丈夫そう


なお，このREADME含め，master ブランチに関しては WTFPL にします．


# ビルド手順


```powershell
git checkout -b build
git checkout master -- install.ps1
./install.ps1

# 成功したら
git checkout -b <branch name>
git branch -d build
```


