---
title: HSTS の導入
date: 2017-01-13 13:30:50
updated: 2017-01-13 13:30:50
tags:
 - H2O
---
独自ドメイン seaoak.jp を独自サーバに移行している中で、
HSTS (HTTP Strict Transport Security) をいう技術を知りました。

 - [HTTP Strict Transport Security - Wikipedia](https://ja.wikipedia.org/wiki/HTTP_Strict_Transport_Security)
 - [HTTP Strict Transport Security - MDN](https://developer.mozilla.org/ja/docs/Web/Security/HTTP_Strict_Transport_Security)
 - [HSTS (HTTP Strict Transport Security) の導入 - Qiita](http://qiita.com/takoratta/items/fb6b3486257eb7b9f12e)
 - [cybozu.com を真に常時 SSL にする話 - Cybozu Inside Out](http://blog.cybozu.io/entry/6096)
 - [HTTP Strict Transport Security comes to Internet Explorer 11 on Windows 8.1 and Windows 7 - Microsoft Edge Dev Blog](https://blogs.windows.com/msedgedev/2015/06/09/http-strict-transport-security-comes-to-internet-explorer-11-on-windows-8-1-and-windows-7/#EctcrrBMSTehzr0J.97)
 - [Preloading HSTS - Mozilla Security Blog](https://blog.mozilla.org/security/2012/11/01/preloading-hsts/)
 - [HTTP Strict Transport Security - The Chromium Projects](https://www.chromium.org/hsts)
 - [HSTS Preload List Submission](https://hstspreload.org/)
 - [HTTPSを使ってもCookieの改変は防げないことを実験で試してみた - 徳丸浩の日記](http://blog.tokumaru.org/2013/09/cookie-manipulation-is-possible-even-on-ssl.html)
 - [RFC6797 HTTP Strict Transport Security (HSTS)](https://tools.ietf.org/html/rfc6797)

もともと全コンテンツを HTTPS 化するつもりだったので、
HSTS も導入したいところです。

せっかくなので、各ブラウザの HSTS Preload List に登録してもらいたい。
そのためには、以下が必要っぽい：

 - `max-age` が `10886400` (18 weeks) 以上であること。[推奨は `63072000` (2 years) らしい。](https://hstspreload.org/#deployment-recommendations)
 - [chrome://net-internals/#hsts](chrome://net-internals/#hsts) で自分のドメインを確認。
 - https://hstspreload.org/ に登録。

最終的に、`h2o.conf` に次の1行を追加すればよいと思われます：

```
header.set: "Strict-Transport-Security: max-age=63072000; includeSubDomains; preload"
```

<!--
本来ならこのヘッダは HTTPS レスポンスにだけ付けるべきなのですが、
`h2o.conf` の `listen:` セクションに Headers Directives は書けないっぽいので、
`global` セクションに書いてしまっています。
HSTS 仕様上は HTTP レスポンスではこのヘッダは無視されるらしいので、OK。
-->

なお、https://hstspreload.org/ に何回も繰り返し書かれているように、
安易に preload 指定するのは避けたほうがよさそうです。
いったん HSTS Preload List に掲載してしまうと、
HTTPS 化できないサブドメインがどうしても必要になった時に非常に困ります。    
https://hstspreload.org/#removal

とりあえず、しばらくは様子見ですね。
