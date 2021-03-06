---
title: ls コマンドの --color オプション
date: 2016-11-12 17:45:19
updated: 2016-11-12 17:45:19
tags:
---

`ls` コマンドの `--color` オプションの挙動が
自分の認識と違っていたので、メモ。

`ls` コマンドに `--color` オプションを指定すると、出力時に、
ファイルタイプ（ディレクトリとかシンボリックリンクとか）
によって色づけ（ハイライト）してくれます。
{% asset_img screenshot01b.png %}
普段の作業にはとても便利な機能なので、
シェルの alias 設定で指定している人も多いのではないでしょうか。

ただ、この `--color` オプションを使うにあたって、
ひとつだけ注意しなければなりません。
`ls` コマンドの出力をパイプにつないでワンライナーを書く時に、
ハイライト機能が有効になっていると正しく動きません。
```
/bin/ls --color | xargs -d '\n' -n 1 hogehoge.pl
```

この対策として、`--color=auto` と指定しておくと、
出力先が端末（ターミナル）でない場合にハイライト機能を無効化してくれます。
とても便利。

で、Seaoak の認識では、単に `--color` と指定した場合は
`--color=auto` になると思っていました。
しかしながら、Ubuntu 16.04.1 LTS や Git for Windows (2.10.2) では、
`--color` は `--color=always` と解釈されるのでした。
ちゃんと man にも明記されています。
```
--color[=WHEN]
       colorize  the output; WHEN can be 'always' (default if omitted),
       'auto', or 'never'; more info below
```

おそらくですが、`ls | less -R` としたときにハイライト機能を有効にしたい、
というのが理由と推測されます。

以上の結論として、
「ワンライナーを書く時は `\ls` または `/bin/ls` と書きましょう」
ということになります。


#### おまけ

ちなみに、似たような便利機能で `-F` オプションがあります。
ファイルタイプによって末尾に `/` とか `@` とか `*` とか付けてくれる機能です。
こちらは出力先が端末か否かに関係なく常に有効になります。
よって、ワンライナーを書く時は、
やっぱり `\ls` または `/bin/ls` と書くのが確実です。


#### おまけ２

`grep` コマンドにも `--color` オプションがあります。
こちらは単に `--color` と指定すると `--color=auto` と解釈されるようです。
man やヘルプには明記されていませんが、
Ubuntu 16.04.1 LTS や Git for Windows (2.10.2) で試すとそうなります。
統一感が無いですね・・・・。


#### おまけ３

`git` コマンドの `grep` で `--color` と指定した場合は `--color=always` と
解釈されます。`man git-grep` 参照。
