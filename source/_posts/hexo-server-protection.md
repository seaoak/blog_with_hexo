---
title: Hexo server をよりセキュアに
date: 2017-07-02 17:29:33
updated: 2017-07-02 17:29:33
tags:
 - Hexo
 - H2O
---

Hexo server への直接アクセスを禁止して、Web サーバ H2O を「SSL/TLS あり Basic 認証ありの reverse proxy」として動かして、その H2O 経由で Hexo server にアクセスするようにします。


## まえがき

静的サイトジェネレータ (Static Site Generator: SSG) のひとつである Hexo には、"Hexo server" という便利な機能があります。Hexo で構築しているブログを更新するとき、Web サーバに deploy せずにプレビューできる機能です。

- Hexo 公式サイト   
  https://hexo.io
- Server | Hexo   
  https://hexo.io/docs/server.html

コマンドラインで "`hexo server -p 8888`" とか実行するだけで Hexo 内蔵の HTTP サーバ機能が起動します。手元の Web ブラウザでポート番号を指定してアクセスすれば、更新後のブログのプレビューが見られます。ブログの原稿（Markdown ファイル）を更新すると、Hexo server がそれをリアルタイムに検知して自動的にコンテンツに反映してくれるので、ブラウザでリロードするだけで結果をチェックできます。

Hexo server の難点は、アクセス制限がかけられないことです。クラウド上の公開サーバで実行すると、インターネットに向けてコンテンツが公開されてしまうのです。プレビュー用なのに。もちろん、ポート番号を誰も使ってなさそうな大きな番号にするとか、アクセス可能な IP アドレスを iptables で制限するとか、緩和策はあります。でも、なんかイマイチ。そもそも、Hexo server は本格的な Web サーバとして作られているわけではないので、セキュリティ的にも不安があります（ちゃんと調べてないので実は安全なのかもしれませんが）。

そこで思いついたのが、「HTTPS サーバを Basic 認識ありの reverse proxy として使って Hexo server にアクセスする」という方法です。「いまさら Basic 認証？」と思われるかもしれませんが、これが意外と使えるのです。

- すべての Web ブラウザが対応している。
- SSL/TLS で通信路を保護すれば認証情報も漏れない。
- サーバ側の設定が簡単（セッション管理とか不要）。

ポイントは、初回アクセスから常に HTTPS を使うことです。間違っても HTTP でアクセスしようとしてはいけません。認証情報が漏れてしまう危険があります。サーバ側の設定で、Basic 認証より先に HTTPS へのリダイレクトをすれば（HTTP リクエストに対して 401 じゃなくて 301 を返せば）大丈夫かもしれませんが、ブラウザの実装に依存しそうな気もするので、自信なし。サーバ側で HSTS を設定しておくか、80番ポートを閉じておくのが安心かも。

Hexo の設定（`_config.yml` ファイルの `url:` フィールドや `root:` フィールド）を変えたくないので、ブラウザからアクセスする際に指定する URL の path 部（スラッシュで始まる部分）として任意のパスを許容する必要があります。したがって、通常の HTTPS サーバとして使っているホスト名 (FQDN) とポート番号 (443/tcp) の少なくともどちらか一方を変えた URL を、その Hexo server 専用として用意する必要があります。ホスト名を変える場合は、使用する HTTP サーバが "virtual host" 機能 (SNI) に対応している必要があります。ポート番号を変える場合は、使用する HTTP サーバが受信ポートごとに異なるアクションを設定できる機能をもっている必要があります。ホスト名を変えると SSL 証明書を取り直さないといけなかったりして面倒なので、今回はポート番号を変えることにします。


## 設定例

```
FQDN : www.example.com
HTTPS 待ち受けポート : 8888/tcp
Hexo server 待ち受けポート : 9999/tcp
```

これまで Hexo server で使っていたポートがあるなら、それをそのまま HTTPS 待ち受けポートに流用するのが良いかもしれません。


## ファイアウォールの設定

これまで Hexo server で使っていたポートをそのまま流用する場合、ファイアウォールの設定は変更不要です。

新たに HTTPS 待ち受けポートを用意する場合は、ファイアウォールでそのポートでの受信を許可します：

```
$ sudo ufw 8888 allow
```

Hexo server の待ち受けポートは loopback アクセスのみ可能にしてください。**外部からアクセス可能にしてはいけません**。せっかくのセキュリティ強化が無意味になってしまいます。もし外部からアクセス可能な設定になっていたら、設定を変更してください：

```
$ sudo ufw 9999 deny
```


## Web サーバ H2O の設定

HTTPS サーバの設定と同じ設定にして、Listen するポート番号を 8888/tcp にします。

`h2o.conf` の記述例：

```yaml
host:
  "www.example.com:8888":
    listen:
      port: 8888
      ssl:
        certificate-file: path/to/server.crt
        key-file: path/to/server.key
    paths:
      "/":
        mruby.handler: |
          lambda do |env|
            require "htpasswd.rb"
            Htpasswd.new("/path/to/htpasswd", "Hexo server at 9999/tcp").call(env)
          end
        proxy.reverse.url: "http://127.0.0.1:9999/"
```

注意点として、H2O で reverse proxy する接続先のホスト名としては、`localhost` ではなく `127.0.0.1` を指定してください。理由は、Hexo server が**デフォルトでは IPv4 接続しか受け付けない**からです。OS (Linux) の設定にも依存するのかもしれませんが、H2O で接続先を `http://localhost:9999/` のようにすると、コネクションごとに IPv4 で接続したり IPv6 で接続したりするようで、接続エラーになったりならなかったりします。H2O の error-log を見ると、一部のリクエストが "connection failed" となっていることが確認できます。ちなみに、H2O で接続先を `http://[::1]:9999/` とかにして IPv6 接続を強制すると、100% 接続エラーになります。

error-log の例：

```
[lib/core/proxy.c] in request:/:connection failed
[lib/core/proxy.c] in request:/favicon.ico:connection failed
```

なお、Hexo server は、デフォルトでは `0.0.0.0` を Listen します（参考：[`heso-server/index.js:10`](https://github.com/hexojs/hexo-server/blob/master/index.js#L10)）。つまり、サーバ上のすべてのインターフェースで IPv4 接続を受け付けます。**IPv6 接続は受け付けません**。Hexo server のヘルプ（下記）には "Bind to all IP address by default" と書かれていますが、実際には IPv4 限定です。Hexo server 起動時に明示的にコマンドラインオプションで `-i ::1` と指定すれば、IPv6 でのローカルループバック接続のみ受け付けるようになります（つまり、Hexo server 自体は IPv6 に対応しています）。もちろん、同様に `-i 127.0.0.1` と指定すれば、IPv4 でのローカルループバック接続のみ受け付けるようになります。そして、同様に `-i ::` と指定すると、**IPv4 と IPv6 のどちらでも受け付けるようになりました**（netstat コマンドで確認すると IPv6 しか Listen していないように見えるのですが、curl コマンドなどで試すと IPv4 でも IPv6 でも接続できました）。試した環境は Ubuntu 16.04.2 LTS (x86_64) と Hexo 3.3.7 の組み合わせです。

<i>デフォルトで IPv6 接続も受け付けるようにするパッチを作る・・・・作りたい。そのうち。</i>

参考）Hexo server のヘルプ：

```
$ hexo server --help
Usage: hexo server

Description:
Start the server and watch for file changes.

Options:
  -i, --ip            Override the default server IP. Bind to all IP address by default.
  -l, --log [format]  Enable logger. Override log format.
  -o, --open          Immediately open the server url in your default web browser.
  -p, --port          Override the default port.
  -s, --static        Only serve static files.

```

参考）デフォルト：

```
$ hexo server -p 9999 >log.txt 2>&1 &
$ netstat -antu | grep ':9999'
tcp        0      0 0.0.0.0:9999            0.0.0.0:*               LISTEN
$
```

参考）IPv4 も IPv6 も接続可能なケース：

```
$ hexo server -i :: -p 9999 >log.txt 2>&1 &
$ netstat -antu | grep ':9999'
tcp6       0      0 :::9999                 :::*                    LISTEN
$
```

参考）試した環境：

```
$ hexo -V
hexo: 3.3.7
hexo-cli: 1.0.3
os: Linux 4.4.0-64-generic linux x64
http_parser: 2.7.0
node: 8.1.2
v8: 5.8.283.41
uv: 1.12.0
zlib: 1.2.11
ares: 1.10.1-DEV
modules: 57
openssl: 1.0.2l
icu: 59.1
unicode: 9.0
cldr: 31.0.1
tz: 2017b
$
$ cat /etc/lsb-release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=16.04
DISTRIB_CODENAME=xenial
DISTRIB_DESCRIPTION="Ubuntu 16.04.2 LTS"
$
```

あと、H2O が reverse proxy 接続する際に IPv4 接続と IPv6 接続を混在させてしまう理由は未調査です。H2O で `getaddrinfo(3)` あたりを呼んでいるコードを追えばわかりそうな気もしますが、未着手です。ちなみに、`/etc/hosts` には `127.0.0.1 localhost` と `::1 localhost` の両方が書いてあります。


## Hexo server の設定

Hexo の設定（`_config.yml` ファイル）を変更する必要はありません。

Hexo server を起動するときに、IP address とポート番号を指定してあげるだけです：

```
$ /usr/bin/nice -19 /usr/bin/ionice -c 3 hexo server -i 127.0.0.1 -p 9999 --debug
```


## 最後に確認

Web サーバに HTTPS 接続できることを確認します。手元のブラウザで `https://www.example.com:8888/` にアクセスしてみてください。Basic 認証が要求され、ユーザ名とパスワードを正しく入力すると、Hexo のコンテンツが表示されるはずです。無事にアクセスできたら、Web サーバのログにエラーが記録されていないことを確認してください。

念のため、Hexo server に直接アクセスできないことを確認します。手元のブラウザで（Hexo server を実行しているサーバ以外から） `http://www.example.com:9999/` にアクセスすると、ファイアウォールに弾かれて接続エラーになるハズです。なお、Hexo server を実行しているサーバ上で `curl` コマンドなどでアクセスすると、おそらく成功してしまいます（ファイアウォールはローカルループバック接続をデフォルトで許可していることが多いので）。
