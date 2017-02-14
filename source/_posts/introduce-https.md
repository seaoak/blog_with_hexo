---
title: HTTPS (SSL/TLS) の導入
date: 2017-01-12 15:05:56
updated: 2017-01-13
tags:
 - H2O
---
独自ドメインを独自サーバに移転するに際し、
全面的に HTTPS (SSL/TLS) を導入することにしました。


 - Google の HTTPS 移行ガイド https://support.google.com/webmasters/answer/6073543
 - [Planning on moving to HTTPS? Here are 13 FAQs!](https://plus.google.com/+JohnMueller/posts/PY1xCWbeDVC)
 - [HTTPS移行でPageRank喪失は起こらない、たとえ302リダイレクトであっても ―― HTTPS移行FAQフォローアップ](https://www.suzukikenichi.com/blog/moving-https-doesnt-lose-pagerank-even-if-302-redirect-is-used/)
 - [SSL and TLS Deployment Best Practices](https://github.com/ssllabs/research/wiki/SSL-and-TLS-Deployment-Best-Practices)
 - [Security/Server Side TLS - MozillaWiki](https://wiki.mozilla.org/Security/Server_Side_TLS)


参考：

 - [SSL/TLS暗号設定ガイドライン～安全なウェブサイトのために（暗号設定対策編）～ - IPA](https://www.ipa.go.jp/security/vuln/ssl_crypt_config.html)
 - [Forward secrecy - Wikipedia](https://ja.wikipedia.org/wiki/Forward_secrecy)
 - [HTTP/2へのmruby活用やこれからのTLS設定と大量証明書設定の効率化について](http://hb.matsumoto-r.jp/entry/2016/02/05/140442)

---
## SSL/TLS のバージョンはどうする？

SSL/TLS 1.0 はいつまでに無効化しなければならないか？    
http://www.intellilink.co.jp/article/pcidss/18.html

SSL and TLS Deployment Best Practices    
https://github.com/ssllabs/research/wiki/SSL-and-TLS-Deployment-Best-Practices    
↑TLS 1.0 は "shouldn't be used"

とりあえず `h2o.conf` で `minimum-version: TLSv1.1` としてみた。

その後、[SSL Server Test (Powered by Qualys SSL Labs)](https://www.ssllabs.com/ssltest/)
でチェックしてみたところ、全部 TLS 1.2 でアクセスできていた
（あるいはアクセス不可だった）。
TLS 1.1 だけに対応しているクライアントはいない模様。

暗号スイート ChaCha20-Poly1305 は AEAD なので TLS 1.2 が必須。

HTTP/2 は TLS 1.2 が必須。

最終的に、`h2o.conf` で `minimum-version: TLSv1.2` とすることとした。

---
## Diffie-Hellman key の生成

デフォルトでは鍵長が短くて危険らしいので、手動で生成して設定しました。

What is the current security status of Diffie-Hellman key exchange? - StackExchange    
http://security.stackexchange.com/questions/112313/what-is-the-current-security-status-of-diffie-hellman-key-exchange    
↑とりあえず鍵長は 2048bit にしておけば良いらしい。

まずは Diffie-Hellman key を生成（数分間かかりました）：

```
$ nice -20 openssl dhparam -out dhparam.pem 2048
```

`h2o.conf` の `ssl:` エントリに `dh-file: dhparam.pem` の行を追加：

```
listen:
  port: 443
  ssl:
    certificate-file: letsencrypt/fullchain.pem
    key-file: letsencrypt/key.pem
    minimum-version: TLSv1.1
    dh-file: dhparam.pem
```

最後に H2O の master プロセスに `kill -HUP` すれば OK。

---
## 暗号スイートの選択

OpenSSL 式のスイート名は `openssl` コマンドで翻訳できます。
ただし、最新の OpenSSL でない場合は一部のスイート名が無視されてしまいます。
たとえば、ChaCha20-Poly1305 とか。

```
$ openssl ciphers -v 'HIGH:!ADH:!MD5' | less
```

2017/Jan/14 時点で、次のような選択をしました：

 - プロトコルは TLS 1.2 以上に限定する。
 - ["Security/Server Side TLS - MozillaWiki"](https://wiki.mozilla.org/Security/Server_Side_TLS) の「Intermediate compatibility (default)」をベースとする。
 - AES-GCM と ChaCha20 とでは、確実性をとって ChaCha20 を優先させる。
 - AEAD (Authenticated Encryption with Associated Data) を優先させる。すなわち、AES-GCM と ChaCha20 を優先させる。
 - `-SHA` (SHA1) は削除。（異議もあるけど、PFS の点でなんとなく不安が残るので）
 - `ECDHE-` と `DHE-` 以外は PFS じゃないので削除。`RSA-` も不可。
 - `ECDHE-ECDSA-AES256-SHA384` と `ECDHE-RSA-AES256-SHA384` の順序を逆に（単に他と揃えたかっただけ）
 - 仕様上は `DHE-RSA-CHACHA20-POLY1305` もあるので追加。OpenSSL/LibreSSL は実装しているみたいだけど、ブラウザには実装されなさそう。 https://tools.ietf.org/html/rfc7905

```
ECDHE-ECDSA-CHACHA20-POLY1305
ECDHE-RSA-CHACHA20-POLY1305
ECDHE-ECDSA-AES128-GCM-SHA256
ECDHE-RSA-AES128-GCM-SHA256
ECDHE-ECDSA-AES256-GCM-SHA384
ECDHE-RSA-AES256-GCM-SHA384
DHE-RSA-CHACHA20-POLY1305
DHE-RSA-AES128-GCM-SHA256
DHE-RSA-AES256-GCM-SHA384
ECDHE-ECDSA-AES128-SHA256
ECDHE-RSA-AES128-SHA256
ECDHE-ECDSA-AES256-SHA384
ECDHE-RSA-AES256-SHA384
DHE-RSA-AES128-SHA256
DHE-RSA-AES256-SHA256
```

なお、`DHE-RSA-AES256-SHA256` は `DHE-RSA-AES256-SHA384` の typo じゃないの？
　と思ったので、調べてみた。しかしググってもよくわからない。
`openssl` コマンドは前者しか知らないと言うので、少なくとも typo ではない。謎。

==========

以下、参考にしたサイト：

PSF (Perfect Forward Secrecy) を満たす鍵交換方式は DHE と ECDHE だけらしい。

httpsだからというだけで安全？調べたら怖くなってきたSSLの話!？ - Qiita    
http://qiita.com/kuni-nakaji/items/5118b23bf2ea44fed96e    
↑暗号スイートの日本語解説記事としてわかりやすいです

我々はどのようにして安全なHTTPS通信を提供すれば良いか - Qiita    
http://qiita.com/harukasan/items/fe37f3bab8a5ca3f4f92    
↑Mozilla 推奨設定の日本語での解説記事。    
↑「優先順位付けのロジック」は必読    
↑「AES 128はAES 256よりも優先される」AES256はコストに見合うか議論があるらしい    
↑最新の [Mozilla SSL Configuration Generator](https://mozilla.github.io/server-side-tls/ssl-config-generator/) と差異があったので要検討　←原文は改版されていた    
↑「OCSP Stapling」の解説もある

その原文：    
Security/Server Side TLS - MozillaWiki    
https://wiki.mozilla.org/Security/Server_Side_TLS    
↑設定内容は Mozilla SSL Configuration Generator と一致。    
↑「Modern compatibility」の「Rationale:」は必読。    
↑「Intermediate compatibility (default)」の「Rationale:」も必読。    
↑モダンなデバイスは AESNI 命令を使えるので AES256 を ChaCha20 より優先する、というのは確かにそうかも？

NginxでHTTP2を有効にする - Qiita    
http://qiita.com/Aruneko/items/8c11f9e45a33457c3c1f    
↑`cipher-suite: ECDHE+AESGCM:DHE+AESGCM:HIGH:!aNULL:!MD5`

自社WebサイトをHTTP/2対応しました。    
https://inaba-serverdesign.jp/blog/20160511/website_http2_nginx.html    
↑`cipher-suite: AESGCM:HIGH:!aNULL:!MD5`    
↑HTTP/2で必須となる暗号スイート `TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256` を優先、とのこと

Let's Encryptを使用したkame.photosのSSL Server Test結果をA+にした    
http://tapira.hatenablog.com/entry/2016/01/31/232130    

SSLCipherSuite を変更し perfect forward secrecy にも対応してみる - さくらVPS CentOS 6.5    
http://impov.hatenablog.com/entry/2014/04/29/010108

本当は怖いAES-GCMの話    
http://d.hatena.ne.jp/jovi0608/20160524/1464054882

Do the ChaCha: better mobile performance with cryptography    
https://blog.cloudflare.com/do-the-chacha-better-mobile-performance-with-cryptography/    
↑AES の代わりに ChaCha20-Poly1305 を推奨    
↑H2O 公式ドキュメントでもこの記事を参照している    
↑Google も ChaCha20-Poly1305 を使っている（Windows 7 Google Chrome で確認）←これはうちの PC が AES 命令を実装していないからです    
↑iPhone5s 以降は AES 命令を実装しているらしい    
↑たしかにクライアントからのリクエストを参考にして切り替えるのは賢いかも ←これが "equal preference cipher groups" 機能

新しいTLSの暗号方式ChaCha20-Poly1305    
http://d.hatena.ne.jp/jovi0608/20160404/1459748671    
↑[仕様上は `DHE-` も定義されている](https://mozilla.github.io/server-side-tls/ssl-config-generator/)が Chrome では `DHE-` は deprecate なので実装されないらしい    
↑AES-GCM よりメッセージ長が短くなるのはうれしい。    
↑「Chrome は、端末がAES-NIとAVXをサポートしている時のみChaCha20-Poly1305よりAES-GCMを優先します。」やはり。    
↑「BoringSSLには equal preference cipher groups機能を実装していました。」でも H2O は LibreSSL なんですよねー

https://github.com/libressl-portable/portable/issues/66    
↑LibreSSL では Issue は上がっているけど equal preference cipher groups は未実装。

SSL/TLSの暗号スイートは何を基準に優先すべきか？(1) ～鍵長と安全性～    
https://blogram.net/2016/07/18/securitybits/    
↑DHE鍵交換方式はリスクがあるらしい

SSL/TLSの暗号スイートは何を基準に優先すべきか？(2) ～考慮する要素～    
https://blogram.net/2016/07/20/ciphersuites-2/

Windowsが対応している暗号スイートの一覧表    
https://blogram.net/2016/07/12/ciphersuites-3/    
↑MAC は SHA1 でも問題ない、という意見（←でも PFS を考えたらどうなのかな？）

暗号スイートの暗号強度と、公開鍵のビット数の設定    
https://http2.try-and-test.net/ecdhe.html    
↑暗号スイートごとの処理の重さについて解説している    
↑`ECDHE-ECDSA-AES256-` のほうが `ECDHE-RSA-AES128-` より軽い？    
↑Let's Encrypt の中間証明書が RSA 2048bit なので、RSA 4096bit のサーバ証明書はムダでは？ ←正解っぽい

ちなみに、H2O では ECDHE (ECDH) の鍵長 (curve) を指定できないのですが、
SSL Server Test のレポートによると、
`ECDH sect571r1 (eq. 15360 bits RSA)` となっているとのこと。
ムダに長い鍵を使っているようです。
DHE (DH) は dhparam ファイルの鍵長と同じ 2048 bits でした。
また、実際のクライアントとの通信では
`ECDH secp384r1` となっているケースもありました。


ECDSA対応CSRを生成して、Let's Encryptをつかう場合    
https://http2.try-and-test.net/letsencrypt_ec_csr.html    
↑「証明書と、暗号スイートの関係」は必読。    
↑今回の独自ドメイン構築では RSA 4096bit のサーバ証明書を取得したので、暗号スイートとして `ECDHE-ECDSA-` を指定しても無意味らしい。

サーバ負荷をRSAとECDSAで比較    
https://http2.try-and-test.net/ecdsa.html    
↑サーバ証明書を ECDSA にすれば TAT が短縮できるかも？（モバイル相手だと微妙？

SSL and TLS Deployment Best Practices    
https://github.com/ssllabs/research/wiki/SSL-and-TLS-Deployment-Best-Practices    
↑とても参考になる記事です。必読。

Mozilla SSL Configuration Generator    
https://mozilla.github.io/server-side-tls/ssl-config-generator/    
↑`cipher-suite: ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256`

iPhone 5s A7 arm64 専用命令の速度 (2) (ARMv8 AArch64)    
http://wlog.flatlib.jp/item/1652    
↑iPhone 5s では AES 命令が実装されている

Nexus 9 Tegra K1 と ARM 64bit Denver    
http://wlog.flatlib.jp/item/1739    
↑Nexus 9 (ARM64 (AArch64), NVIDIA Denver) では AES 命令が実装されている

The Nexus 5X And 6P Have Software-Accelerated Encryption, But The Nexus Team Says It's Better Than Hardware Encryption    
http://www.androidpolice.com/2015/09/30/the-nexus-5x-and-6p-have-software-accelerated-encryption-but-the-nexus-team-says-its-better-than-hardware-encryption/    
↑Nexus 5X and 6P は AES ハードウェアを使わずに ARMv8 命令を使っているらしい

ハードウェアの AES 命令サポート状況：
 - iPhone5s 以降は AES 命令を実装している
 - Nexus 9 (ARM64, NVIDNA Denver) は AES 命令を実装している
 - ARM の 64bit アーキテクチャ ARMv8 の AArch64 は AES 命令を実装している
 - x86 プロセッサについては Wikipedia 参照： https://ja.wikipedia.org/wiki/AES-NI
 - GCM を高速化する CLMUL 命令も x86 プロセッサに実装されている： https://ja.wikipedia.org/wiki/CLMUL_instruction_set
 - 構築中の VPS のプロセッサは AES 命令を実装していた `/proc/cpuinfo`
 - Seaoak の自宅 PC は AMD Phenom II X4 970 プロセッサなので未サポート（だから Google Chrome で Google にアクセスすると ChaCha20 が選択されるのかもしれない）←正解

---
## サーバ設定のチェック

SSL Server Test (Powered by Qualys SSL Labs)    
https://www.ssllabs.com/ssltest/

とりあえず試してみたら、`seaoak.jp` は "Grade B" 判定でした。

`cipher-suite:` を ["SSL and TLS Deployment Best Practices"](https://github.com/ssllabs/research/wiki/SSL-and-TLS-Deployment-Best-Practices)
の推奨に変えたら "Grade A" 判定になりました。IPv4 と IPv6 の両方とも。
Forward Secrecy も "Yes" でした。
IE10 を除いて、それなりに幅広く対応できている模様。
IE11, Android 4.4.2 以上、Safari7 (iOS7.1) 以上、Java 8 以上、に対応です。
すべて TLS 1.2 接続でした。
この結果を見る限り、TLS 1.1 を有効にするメリットは無いのかもしれない。

TLS 1.2 以上に変更して、暗号スイートも変更して、再チェック。
結果は変わらず "Grade A" でした。
ほとんどのクライアントで `ECDHE-RSA-AES128-GCM-SHA256` が選択されており、
一部 (Chrome/Firefox) で `ECDHE-RSA-CHACHA20-POLY1305` が選択されるという、
期待したとおりの結果になっています。
古い Windows Phone + IE11 と、古い Safari で、
GCM でない `ECDHE-RSA-AES128-SHA256` が選択されてしまっていましたが、
まぁ、許容範囲でしょう。
なお、Windows 7/8.1 + IE11 で `DHE-RSA-AES128-GCM-SHA256` が選択されていたので、
やはり DHE 鍵交換方式は必要と思われます。

---
## リザンプションとは？

TLS Session Resumption のこと。
http://www.slideshare.net/kazuho/http-58452175/66

これを有効にしておかないと、パフォーマンスに影響があるらしい。    
https://github.com/ssllabs/research/wiki/SSL-and-TLS-Deployment-Best-Practices#32-use-session-resumption

とりあえず H2O はデフォルトでよろしくやってくれるみたい。    
https://h2o.examp1e.net/configure/base_directives.html#ssl-session-resumption

Yahoo! JAPAN Tech Blog に実コードを用いた詳しい解説記事があります：    
細かすぎて伝わらないSSL/TLS    
https://techblog.yahoo.co.jp/infrastructure/ssl-session-resumption/

---
## おまけ： ESET Smart Security 9 が悪いことをする

Windows PC からのアクセスが HTTP/2 にならない場合は ESET Smart Security 9 の「SSL/TLSプロトコルフィルタリング機能」のせいかも？    
https://inaba-serverdesign.jp/blog/20160511/website_http2_nginx.html

Seaoak はつい先日 ESET Smart Security 9 にアップデートしたところです。
で、実際、自分のサイトに Google Chrome 56.0.2924.59 beta (64-bit)
でアクセスしたらこの現象を踏みました。
Web サーバへのアクセスは HTTP/1.1 になっていて、
証明書の発行元は ESET SSL Filter CA になってしまっていました。
ESET Smart Security 9 の設定を変更したら、
無事に HTTP/2 アクセスになって「青いイナズマ」アイコンが見られました。

---
追記：    
別に借りている CentOS 7 のサーバは、TLS 1.0 までしか対応していなかった。
さらに、暗号スイートの候補を Mozilla の "Intermediate compatibility"
相当にする必要がありました。

追記：    
ガラケー (docomo) は TLS 1.0 までしか対応しておらず、
さらに、暗号スイートの候補を Mozilla の "Intermediate compatibility"
相当にしたところ、安全ではないと言われてしまった。
（無視してアクセスすることはできた）
