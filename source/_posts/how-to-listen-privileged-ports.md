---
title: 一般ユーザ権限で特権ポートを bind したい
date: 2017-01-11 08:32:22
updated: 2017-01-15
tags:
 - H2O
---
Web サーバ [H2O](https://h2o.examp1e.net) を
root 権限の無い一般ユーザで運用したいと考えました。

通常、root 権限で h2o を実行すると、
TCP port 80 (HTTP) と port 443 (HTTPS) を bind して、
その後 nobody ユーザに `setuid` で切り替えます。
nobody ユーザはシェルにログインできない一般ユーザなので、安全。

なぜ先に TCP ポートを bind するのかというと、
1024 番未満のポートは "privileged port"
（[well-known port numbers](https://ja.wikipedia.org/wiki/%E3%83%9D%E3%83%BC%E3%83%88%E7%95%AA%E5%8F%B7), 予約ポート, 特権ポート）
と呼ばれるポートなので一般ユーザ権限では触れないからです。
HTTP プロキシとかでよく使われる port 8080 なら root 権限は不要なのですが。

ところで、実は Seaoak はこの nobody ユーザが好きではありません。
たとえば、あるファイル／ディレクトリについて、
CGI プログラムとふつうの一般ユーザの両方が書き込めるようにすると、
`chmod o+w` が必要になるのが気持ち悪い。
あと、perlbrew とか nvm とかも利用したいです。
「いまさら CGI かよ」という意見もあるとは思いますが……。

もちろん、ふつうの一般ユーザ権限で Web サーバを運用すると、
万一、プロセスを乗っ取られた時に、被害が大きくなります。
sudo できるユーザだったりしたら最悪です。

いちおうそういうリスクは認識した上で、トライ。

ちなみにサーバ環境は `Ubuntu 16.04.1 LTS (Xenial Xerus) x86_64` です。


## 事前準備

ファイアウォールで標準のポートを開けておきます：

```
$ sudo ufw allow 80
$ sudo ufw allow 443
$ sudo ufw status
```

なお、いちおう UDP ポートも開けておきました。（後述）


## 案１： Linux Capabilities (setcap)

root 権限が無くても特権ポートにアクセスできるようにする仕組みがありました。

 - [Linux] 一般ユーザのプロセスをポート1024番未満でBindする方法 - Roguer    
   http://roguer.info/2012/07/23/5727/
 - 第3回 権限を最小化するLinuxカーネルケーパビリティ    
   http://www.atmarkit.co.jp/fsecurity/rensai/lids03/lids01.html
 - capabilities - Linux のケーパビリティ (capability) の概要    
   https://linuxjm.osdn.jp/html/LDP_man-pages/man7/capabilities.7.html

特定の実行ファイルに `CAP_NET_BIND_SERVICE` capability を設定すると、
そのプログラムは特権ポートにアクセスできるらしいです。

さっそく試してみます：

```
$ sudo setcap CAP_NET_BIND_SERVICE+ep /usr/local/bin/h2o
$ sudo getcap /usr/local/bin/h2o
```

これで `h2o -m worker` はうまく動きました。

しかし、`h2o -m daemon` と `h2o -m master` はダメでした。
`/usr/local/bin/h2o` から呼ばれているシェルスクリプト
`/usr/local/share/h2o/start_server` の中で、特権ポートが
open できないと言われてしまいます。
capability に `+i` (inheritable) を加えて
`setcap CAP_NET_BIND_SERVICE+eip` と指定してもダメでした。
capability がうまく継承されないようです。

とりあえず、元に戻します：

```
$ sudo setcap -r /usr/local/bin/h2o
$ sudo getcap /usr/local/bin/h2o
```


## 案２： ポートのリダイレクト

ファイアウォール (iptables) で特権ポートから非特権ポートにリダイレクトして、
Web サーバはその非特権ポートを bind する、という手段がありました。

 - 80番ポートへ届いたパケットをiptablesでローカルの上位ポートに転送する    
   http://qiita.com/kawaz/items/ed0030cb29c7d0497b63
 - Internal Port Forwarding on Linux using the Firewall    
   https://linuxacademy.com/howtoguides/posts/show/topic/11630-internal-port-forwarding-on-linux-using-the-firewall
 - iptables でローカルの上位ポートに転送しているときにそのポートへの直接アクセスを禁止する - Qiita    
   http://qiita.com/ngyuki/items/1576d62ab9123dd20a4a

２番目の記事の「Ubuntu\*/Debian systems can use ufw as a firewall for port redirection:」を参考にしました。
また、３番目の記事の「成功その３」を採用させていただきました。

まず、リダイレクト先のポート番号は以下を参考に適当に選びます：

 - [ポート番号 - Wikipedia](https://ja.wikipedia.org/wiki/%E3%83%9D%E3%83%BC%E3%83%88%E7%95%AA%E5%8F%B7)
 - [TCPやUDPにおけるポート番号の一覧 - Wikipedia](https://ja.wikipedia.org/wiki/TCP%E3%82%84UDP%E3%81%AB%E3%81%8A%E3%81%91%E3%82%8B%E3%83%9D%E3%83%BC%E3%83%88%E7%95%AA%E5%8F%B7%E3%81%AE%E4%B8%80%E8%A6%A7)
 - [IANA によるポート番号の一覧 / Service Name and Transport Protocol Port Number Registry - IANA](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml)
 - [エフェメラルポート - Wikipedia](https://ja.wikipedia.org/wiki/%E3%82%A8%E3%83%95%E3%82%A7%E3%83%A1%E3%83%A9%E3%83%AB%E3%83%9D%E3%83%BC%E3%83%88)

本来はエフェメラルポートを使うべきなのかもしれませんが、なんとなく気分で、誰も使っていなさそうなポート番号を適当に選びました：

    port 5210 : redirect from  80 (HTTP)
    port 5211 : redirect from 443 (HTTPS)
    port 5212 : always drop

次に、ufw の設定ファイル `/etc/ufw/before.rules` および `/etc/ufw/before6.rules`
に以下の行を追加します：

```
*nat
:PREROUTING ACCEPT [0:0]
-A PREROUTING -p tcp --dport 5210 -j REDIRECT --to-port 5212
-A PREROUTING -p udp --dport 5210 -j REDIRECT --to-port 5212
-A PREROUTING -p tcp --dport 5211 -j REDIRECT --to-port 5212
-A PREROUTING -p udp --dport 5211 -j REDIRECT --to-port 5212
-A PREROUTING -p tcp --dport   80 -j REDIRECT --to-port 5210
-A PREROUTING -p udp --dport   80 -j REDIRECT --to-port 5210
-A PREROUTING -p tcp --dport  443 -j REDIRECT --to-port 5211
-A PREROUTING -p udp --dport  443 -j REDIRECT --to-port 5211
COMMIT
```

Seaoak はとりあえず設定ファイルの先頭部分（コメント行
`# Don't delete these required lines, otherwise there will be errors`
の前）に上記の行を挿入しました。

具体的な手順としては、次のようになります：

```
$ sudo vi /etc/ufw/before.rules
$ sudo vi /etc/ufw/before6.rules
$ sudo ufw allow 5210
$ sudo ufw allow 5211
$ sudo ufw deny  5212
$ sudo ufw disable
$ sudo ufw enable
```

`ufw deny 5212` は念のためです。
なお、今回試した限りではサーバのリブートは不要でした。

次に、H2O の設定ファイル `h2o.conf` を変更します。
`listen:` ディレクティブで指定するポート番号を "80" から "5210" に、
"443" から "5211" に、それぞれ変更します。
ここで、**`hosts:` ディレクティブに書く `host:port` の `:port` 部分は
<span style="color:red">`:80` とか `:443` とかのまま変更してはいけません。</span>**
なぜなら、クライアントがリクエストした URL は、
あくまでも port 80 / 443 に対するものだからです。
ここを `:5210` とか `:5211` とかに変えてしまうと、
クライアントがリクエストした URL （の `host:port` 部分）
にマッチしなくなってしまいます。

ちなみに、困ったことに、`h2o.conf` で `listen:` ディレクティブを
global-level に記述している場合、上記のようなミスをすると、
**無条件に `hosts:` ディレクティブの先頭のエントリにマッチしたもの**として扱われてしまいます。
[公式ドキュメントにも明記されています。](https://h2o.examp1e.net/configure/base_directives.html#listen-configuration-levels)
エラーにはなりません。
この罠に Seaoak はハマりました。
今後も同じようなミスをする可能性があるので、対策として、
Seaoak の `h2o.conf` では `hosts:` ディレクティブの先頭に
「番兵」（ダミー）を置くことにしました：

```
hosts:
  "sentinel.example.com":
    paths:
      "/":
        file.dir: /dev/null
    access-log:  "| rotatelogs -l access-log.sentinel.%Y%m%d 86400"
  "seaoak.jp:443":
    paths:
      "/":
        file.dir: /path/to/doc-root
    access-log:  "| rotatelogs -l access-log.root.%Y%m%d 86400"
  "seaoak.jp:80":
    paths:
      "/":
        redirect:
          url: "https://seaoak.jp/"
          status: 301
    access-log:  "| rotatelogs -l access-log.root-nossl.%Y%m%d 86400"
```

ちなみに、`file.dir: /dev/null` とすると "404 Not Found" が返ります。

閑話休題。

以上の状態で h2o を動かしてみると、`h2o -m worker` も `h2o -m daemon` も
`h2o -m master` も動きました。特にエラーメッセージも出ません。

ブラウザで http://seaoak.jp とか https://seaoak.jp
とかにアクセスしてみると、問題なくアクセスできました。
また、http://seaoak.jp:5210 とか https://seaoak.jp:5211
とかにアクセスしてみると接続エラーになります。
すばらしい！！

また、別に借りているサーバから IPv6 でアクセスすると無事成功しました。

カンペキです。


## 案３： Linux Capabilities (Ambient capabilities)

案１で試した `setcap` による capabilities 機能は、正確には
"File capabilities" と呼ぶものらしく、それとは別に、
"Ambient capabilities" というものがあるらしいです。

 - 明日使えない Linux の capabilities の話 - Overjoy への道    
   http://nojima.hatenablog.com/entry/2016/12/03/000000

Seaoak は試していませんが、もしかするとうまい手があるかもしれません。

ご参考まで。


## How about UDP ports ?

とりあえず UDP のポート 80 / 443 も開けておいたほうが良さそうです。

 - Does HTTP use UDP - Stack Overflow    
   http://stackoverflow.com/questions/323351/does-http-use-udp
 - Googleの新プロトコルQUICを試す - ぼちぼち日記    
   http://d.hatena.ne.jp/jovi0608/20130628/1372408950    
   「QUIC は UDP のポート80番に接続に行きます。」

いちおう H2O でも QUIC を実装しようという Issue が上がっています。    
https://github.com/h2o/h2o/issues/275


## オチ？

h2o プロセスがダウンしたときに自動的に再実行したい、とか言うと、
結局 systemd のお世話になるので、上記の話はすべて無駄になりそうです。
