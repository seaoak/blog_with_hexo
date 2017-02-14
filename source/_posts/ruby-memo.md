---
title: Ruby めも
date: 2017-01-17 19:53:26
updated: 2017-01-18
tags:
---

[Web サーバ H2O](https://h2o.examp1e.net) の設定には mruby を使うので、
H2O の設定ファイル `h2o.conf` を生成する自前の YAML トランスレータ（？）も
Ruby で書いてみることにしました。
Ruby 書くのなんて何年ぶりだろう・・・・。

で、ハマったのが、`String#match` の挙動です。`Regexp#match` と同じハズ。    
https://docs.ruby-lang.org/ja/2.4.0/class/String.html#I_MATCH    
https://docs.ruby-lang.org/ja/2.4.0/method/Regexp/i/match.html

第2引数として `pos` が渡せるのですが、`pos` に `0` 以外の値を渡した場合、
「文字列先頭にマッチする正規表現」（つまり `^` と `\A`）は**絶対にマッチしません**。

```bash
$ ruby -e 'p "abc".match(/^./, 1)'
nil
$
```

ドキュメントに書いておいてほしかったなぁ。
