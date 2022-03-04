---
title: Hexo の導入
date: 2016-11-06 22:10:00
updated: 2017-01-24 15:05:12
tags:
 - Hexo
---
静的サイトジェネレータ Hexo を始めました。

https://hexo.io

https://github.com/hexojs/hexo/

Hexo は [Node.js](https://nodejs.org) で動く SSG (Static Site Generator) です。


## SSG (Static Site Generator) とは？

SSG に関しては以下のリンクを参照してください：

 - https://staticsitegenerators.net
 - https://www.staticgen.com
 - http://mojix.org/2012/12/07/static-site-generation
 - http://tamura.goga.co.jp/article/430486919.html


## インストール

まず、Node.js を入れておいてください。 ※参考記事「{% post_link node-memo %}」

続いて、Hexo のコマンドをインストールします：

```bash-prompt
$ npm install hexo-cli -g
```

NVM で新しいバージョンの Node.js をインストールした場合には、
毎回これが必要です。


## 新しいブログの作成

```bash-prompt
$ hexo init new_my_blog
$ cd new_my_blog
$ hexo server -p 5210
```

これで Hexo 内蔵の仮 HTTP サーバがポート 5210 番で起動します。
ポート番号は適当に選んでください。
あらかじめファイアウォールでポートを開けておく必要があります。

あとはブラウザで http://www.example.com:5210 とかアクセスすれば、
"Hello World" ページが見られるはずです。

Hexo server は Ctrl-C で止められます。

## ブログの初期設定

Hexo の設定ファイルは `_config.yml` という YAML ファイルです。

```bash-prompt
$ vi _config.yml
```


## デプロイ前の確認

```bash-prompt
$ (nice -10 hexo clean --debug && nice -10 hexo server -p 5210 --debug) 2>&1 | tee z
```
