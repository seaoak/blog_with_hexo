---
title: Web サーバ H2O の導入
date: 2017-01-10 13:55:22
updated: 2017-01-14
tags:
 - H2O
---
独自ドメインを独自サーバに移転するに際し、
Web サーバをどれにしようかと考えました。

ゼロから新しく構築するので、当然ながら HTTP/2 前提です。

Apache は以前から使っていたのですが、
設定ファイルが複雑で、あまり好きではありませんでした（自由度の高さは認めます）。
nginx は触ったことがないので以前から興味がありました。
本も2冊買いました。

そんなある日、HTTP/2 に最適化されているとうたう
H2O というサーバの存在を知りました。
DeNA のひとがメインで開発している OSS です。

 - 公式サイト https://h2o.examp1e.net
 - GitHub https://github.com/h2o/h2o/
 - HTTP/2 対応は一番乗りだったらしい http://www.slideshare.net/kazuho/http-58452175/3
 - とにかく速いらしい https://h2o.examp1e.net/benchmarks.html
 - 特に新しいページを開いた時の最初の描画 (first-paint) が速いらしい http://www.slideshare.net/kazuho/http-58452175/38
 - 暗号ライブラリとして OpenSSL の代わりに [LibreSSL](https://www.libressl.org) が使えるのでちょっと安心かも
 - mod_rewrite の黒魔術から解放される http://www.publickey1.jp/blog/16/httpshttp2httpdevelopers_summit_2016.html
 - H2O は TLS Session resumption のクラスタ対応ができているらしい https://speakerdeck.com/matsumoto_r/pfswokao-lu-sitatlszhong-duan-tongx-mrubyniyoruda-liang-domeinshe-ding-falsexiao-lu-hua?slide=12
 - H2O は TLS Session ticket の自動更新に対応済みらしい https://speakerdeck.com/matsumoto_r/pfswokao-lu-sitatlszhong-duan-tongx-mrubyniyoruda-liang-domeinshe-ding-falsexiao-lu-hua?slide=13
 - HTTP/2 で優先度の書き換えもやってくれるらしい http://www.slideshare.net/kazuho/http-58452175/39

せっかくの機会なので、試してみることにしました。

ちなみにサーバ環境は `Ubuntu 16.04.1 LTS (Xenial Xerus) x86_64` です。

追記：デフォルトで IPv6 にも対応していました。


## インストール

ソースコードを git clone してビルドしました。

```
$ sudo apt-get install -y cmake zlib1g-dev
$ sudo apt-get install -y bison ruby ruby-dev
$ git clone https://github.com/h2o/h2o.git
$ cd h2o
$ git tag
$ git checkout v2.0.4
$ nice -20 cmake -DWITH_BUNDLED_SSL=on -DWITH_MRUBY=on .
$ nice -20 make
$ sudo make install
```

一発でビルドに成功しました。

なお、RPM なひと（CentOS とか）では `ruby-dev` の代わりに `ruby-devel` かも。

とりあえず添付されているサンプルを実行してみる：

```
動作確認用のポートを開ける
$ sudo ufw allow 5210
$ sudo ufw allow 5211
$ sudo ufw status
自動的に IPv6 のポートも開けてくれる。

h2o.conf のポート番号だけ書き換えて実行
$ vi examples/h2o/h2o.conf
$ h2o -c examples/h2o/h2o.conf
```

使ったポート番号は適当です。
1024 番未満のポートは特権ポートなので使えません。
port 8080 と port 8081 はポートスキャンがうざいので避けたほうがいいです。

ブラウザで http://hogehoge.example.com:5210 とか
https://hogehoge.example.com:5211 とかにアクセスすれば、
"Welcome to H2O" のページが見られるはずです。


## バージョンアップ

```
$ cd h2o
$ make clean
$ git fetch
$ git tag
$ git checkout v2.0.6
$ nice -20 cmake -DWITH_BUNDLED_SSL=on -DWITH_MRUBY=on .
$ nice -20 make clean
$ nice -20 make
$ sudo make install
```

あとは H2O の master プロセスに `kill -HUP` するだけ。


## 設定ファイル

設定ファイルは `h2o.conf` です。
書き方は[公式ドキュメント](https://h2o.examp1e.net/configure.html)参照。
Apache に比べてはるかにシンプルです。

```
$ vi h2o.conf
```

編集が終わったら、問題が無いかチェック：

```
$ h2o -t
```

OK なら H2O の master プロセスに `kill -HUP` すると再読み込みしてくれる。


## ログのローテーションは `rotatelogs` コマンドで

[公式ドキュメント](https://h2o.examp1e.net/configure.html)では
error-log や access-log をローテーションさせるのに
`rotatelogs` コマンドを使っています。

`rotatelogs` コマンドは `apache2-utils` パッケージに含まれています。

```
$ sudo apt-get install -y apache2-utils
```

------------------------------------------------------------------------------
以上。
