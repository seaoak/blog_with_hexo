---
title: Git for Windows でシェルスクリプトが動かなくなった
date: 2016-11-20 20:36:56
updated: 2016-11-21
tags:
---

[Git for Windows](https://git-for-windows.github.io/) (https://git-for-windows.github.io/) を愛用しています。
Windows 7 上で bash が動きます。
本来は分散型バージョン管理システム git を Windows 上で使うための環境ですが、
UNIX の基本的なコマンド群がそろっており、
perl やシェルスクリプトが使えるので、
ファイル処理やテキスト処理など、かなりいろいろできます。
Windows 10 の Bash on Ubuntu on Windows は触ったことがないので比較はできませんが、
少なくとも Windows 7 上では日本語も含めて全く問題なく使えています。

Git for Windows をインストールすると、拡張子 `.sh` に関連付けが設定されます。
エクスプローラー上でシェルスクリプトファイルをダブルクリックするだけで実行できます。
もちろん bash を起動してコマンドライン上で実行させることもできますが、
ダブルクリック一発で動くので、完全にバッチファイルの代わりに使えます。
とても便利。

ずっと問題なく使えていたのでアップデートもせずに使っていたのですが、
ふと気が向いて Git for Windows を最新版にアップデートしたところ、
ダブルクリックで起動したシェルスクリプトが意図しない挙動を示すようになってしまいました。

* 旧： `Git-1.9.5-preview20150319.exe`
* 新： `Git-2.10.2-64-bit.exe`

bash を起動してコマンドライン上でそのシェルスクリプトを実行すると問題なく動きます。
ダブルクリックして実行したときだけダメ。


### 原因

いろいろ試行錯誤して調べた結果、原因が判明しました。
シェルスクリプトをダブルクリックして起動すると、
**シェルの alias 設定が有効な状態**で実行されてしまい、
ls コマンドの出力がカラー化＆ファイルタイプ記号付きになってしまうのでした。
つまり余計なエスケープシーケンスや記号が付与されてしまうわけです。
この出力を生のファイル名一覧だと思ってパイプにつないで処理しようとすると、
当然ながら意図しない挙動になってしまいます。

具体的には、`~/.bashrc` での以下の alias 設定が有効になってしまっていました：
```
alias ls='ls -F --color --show-control-chars'
```

ややこしいことに、旧バージョンでも alias 設定が有効な状態だったのですが、
**なぜかシェルスクリプト内でパイプに出力する時だけ ls コマンドの出力がカラー化＆ファイルタイプ記号付きにならなかった**ため、
問題が顕在化しなかったのでした。
この挙動は `--color=auto` オプション指定時の挙動に似ていますが、

* `--color` とだけ指定した場合は `--color=always` と解釈されるのが仕様 by `man ls(1)`
* `-F` オプションについては出力先による自動 ON/OFF 機能がない

ということから予期しない挙動だと言えます。
詳しくは以前の記事「{% post_link ls-color-option-default %}」を参照してください。

なお、`~/.bashrc` などで上記の alias 設定をしていなかったとしても、
`/etc/profile.d/aliases.sh` により以下の alias がデフォルトで設定されます。
```
alias ls='ls -F --color=auto --show-control-chars'
```
すなわち、カラー化は回避できますが、`-F` オプションによる余計な記号の追加は避けられません。


### なぜ alias 設定が有効になってしまうのか

`/usr/bin/bash --login -i` というオプション付きで bash にシェルスクリプトが渡されるから。

`man bash(1)` によれば、

```
   A login shell is one whose first character of argument zero is a -,  or
   one started with the --login option.

   An  interactive  shell  is one started without non-option arguments and
   without the -c option whose standard input and error are both connected
   to  terminals  (as determined by isatty(3)), or one started with the -i
   option.  PS1 is set and $- includes i if bash is interactive,  allowing
   a shell script or a startup file to test this state.
```

とのことなので、bash は "interactive login shell" として起動されたことになります。
そして、さらに man を読むと、

```
   When bash is invoked as an interactive login shell, or as a  non-inter‐
   active  shell with the --login option, it first reads and executes com‐
   mands from the file /etc/profile, if that file exists.   After  reading
   that file, it looks for ~/.bash_profile, ~/.bash_login, and ~/.profile,
   in that order, and reads and executes commands from the first one  that
   exists  and  is  readable.  The --noprofile option may be used when the
   shell is started to inhibit this behavior.
```

とのことなので、bash は `/etc/profile` を読み込みます。
`/etc/profile` の中では `/etc/profile.d/*.sh` を順次読み込みます。
`/etc/profile.d/aliases.sh` を読み込むと、次のように ls コマンドの alias が設定されます：

```
alias ls='ls -F --color=auto --show-control-chars'
```

また、`~/.bash_profile` 経由で `~/.bashrc` も読み込まれるので、
個人的に ls コマンドの alias 設定をしていれば上書きされます。

bash に `--login -i` オプションを指定しなければ、これらのファイルは読み込まれず、
ls コマンドの alias 設定はされません。
bash のコマンドライン上でシェルスクリプトを実行した場合はこちらの挙動になります。


### 誰が bash に余計なオプションを付けているのか

`git-bash.exe` です。

Windows のレジストリを見ると、拡張子 `.sh` に対して
`C:\Program Files\Git\git-bash.exe` が関連付けられています。

`git-bash.exe` の詳細と、拡張子の関連付け設定については、
それぞれ後述の「おまけ」を参照してください。

とりあえず結論を言うと、`git-bash.exe` は**必ず** `--login -i` オプション付きで
bash を起動するようにハードコーディングされています。    
https://github.com/seaoak/MINGW-packages/blob/master/mingw-w64-git/git-bash.rc

`--login -i` オプション無しに bash を起動させるオプションは `git-bash.exe` にはありません。


### 対策

`git-bash.exe` を使わない。

Git for Windows のコミッターいわく：
{% blockquote dscho https://github.com/git-for-windows/git/issues/946#issuecomment-258831971 %}
Please understand that `git-bash.exe` is the executable that is intended to open the *interactive* Git Bash.

What you most likely wanted to do was to call `C:\Program Files\Git\bin\bash.exe` instead (which is *still* not the *real* Bash, but a redirector that sets up appropriate environment variables first).
{% endblockquote %}
とのことなので、そもそもシェルスクリプトに `git-bash.exe` を関連付けるのが妥当なのか疑問。

しかし、`bash.exe` は Windows で言うところの「コンソールプログラム」なので、
`bash.exe` を直接実行すると mintty ではなく `cmd.exe` が立ち上がってしまいます。
そのため、日本語表示が化ける。

そこで、明示的に mintty 経由で `bash.exe` を呼んでシェルスクリプトと引数を渡します：
```
"C:\Program Files\Git\usr\bin\mintty.exe" --dir "%W" "C:\Program Files\Git\bin\bash.exe" "%L" %*
```
このコマンドラインを拡張子 `.sh` に関連付けしてあげれば OK.

なお、`C:\Program Files\Git\bin\bash.exe` の代わりに「素の bash」である
`/usr/bin/bash` を mintty に渡しても実行してくれますが、
最低限の PATH 設定も無い状態なので、使い物になりません。
上記のコミッターのコメントの言うとおりです。
`git-bash.exe` で `/usr/bin/bash` を直接 mintty に渡しても（一見）ちゃんと使えているのは、
`--login -i` オプションのおかげです（しかし alias 設定という副作用があるのは上述の通り）。


### おまけ： ファイルの関連付けの設定方法

Windows のレジストリを見ると、拡張子 `.sh` に対して
（正確には拡張子 `.sh` に結びつけられた "sh_auto_file" タイプに対して）
ただひとつのアクション "open" が設定されており、そのコマンドラインは、
```
"C:\Program Files\Git\git-bash.exe" --no-cd "%L" %*
```
となっています。

レジストリのキーは `HKEY_CLASSES_ROOT\sh_auto_file\shell\open\command` です。

これを上述の mintty 呼び出しのコマンドラインに書き換えてあげれば OK です。

`%L` とか `%W` とかの意味はこちらのページが参考になります：    
http://pf-j.sakura.ne.jp/program/winreg/classes.htm

レジストリを直接いじるのは怖いので、
Seaoak は FileTypesMan というフリーソフトを使わせていただいています（感謝！）。
Windows 7 Pro 64bit 版で使えていますが、Windows 10 で使えるかはわかりません。    
http://www.nirsoft.net/utils/file_types_manager.html

なお、シェルスクリプトに別のファイル／フォルダをドラッグ＆ドロップすると、
"open" アクションが実行される模様（実際の挙動から）。
ただし、このとき、カレントディレクトリは `/c/Windows/system32` (`C:\Windows\system32`)
となり、シェルスクリプト自身およびドラッグ＆ドロップされたファイル／フォルダは
ともに絶対パス（フルパス）で bash に渡されます。


### おまけ： git-bash.exe について

`git-bash.exe` に関するドキュメントはこの世に存在しないっぽい。
GitHub の Issue を見ても、コミッターが「無い」と言ってる：    
https://github.com/git-for-windows/git/issues/130#issuecomment-98724488

`git-bash.exe` の実体は `git-wrapper.c` です：    
https://github.com/seaoak/MINGW-packages/blob/master/mingw-w64-git/PKGBUILD#L152

`git-wrapper.c` のコマンドラインオプション処理部分は 389 行目付近：    
https://github.com/seaoak/MINGW-packages/blob/master/mingw-w64-git/git-wrapper.c#L389

`git-bash.exe` 内部で mintty / bash を呼ぶ時のコマンドライン文字列はこちらで指定：    
https://github.com/seaoak/MINGW-packages/blob/master/mingw-w64-git/git-bash.rc

`git-bash.exe` が誕生するに際して議論があった模様（全部は読んでません）：    
https://github.com/git-for-windows/git/pull/42


### おまけ： Git for Windows のインストーラーの設定？

https://github.com/git-for-windows/build-extra/blob/master/installer/install.iss

"`git-bash.exe`" で検索！


### おまけ： mintty について

Windows 標準のコマンドライン `cmd.exe` の代わりに使えるターミナル。
日本語表示 (UTF-8) に対応していたりするので、mintty のほうが便利。

リポジトリ：    
https://github.com/mintty/mintty

マニュアル：    
https://mintty.github.io/mintty.1.html

なお、Git for Windows のリポジトリには mintty のパッケージが２個ある。

* https://github.com/git-for-windows/MSYS2-packages/tree/master/mintty-git
* https://github.com/git-for-windows/MSYS2-packages/tree/master/mintty

実際に Git for Windows をインストールすると
`/usr/bin/mintty` (`C:\Program Files\Git\usr\bin\mintty.exe`)
しか無いのですが、どちらのパッケージのものかは不明（調査不足）。
ただし、どちらのパッケージも上記の mintty リポジトリを参照している様子なので、
とりあえず実用上問題はないでしょう。


### おまけ： MinGW と MSYS と Mingw-w64 と Git for Windows の関係

http://d.hatena.ne.jp/m-hiyama/20151013/1444704189
