---
title: Gandi.net の無料メールで DMARC を設定してみる
date: 2022-03-11 10:38:12
tags:
---

ふと、新しいドメインを衝動買いしてしまいました。
[.dev ドメイン](https://www.gandi.net/ja/domain/tld/dev)です。
取得費用 1759円で安かった（更新料も同額）。運用中の汎用 .jp ドメインの半額です。
レジストラは [Gandi.net](https://gandi.net) を選びました。
フランスの企業ですが、日本語サイトがちゃんとあって、手続きは全部日本語でできます。支払いも日本円で OK （クレカか PayPal）。
ただし、マニュアルとかドキュメントは英語です。英語読めないひとにはオススメしません。
追加費用なしで Whois 情報の保護（ドメイン所有者とかの個人情報を隠してくれる）もやってくれるので、安心です。

- Gandi.net   
  https://gandi.net
- .DEV ドメイン名 - Gandi.net   
  https://www.gandi.net/ja/domain/tld/dev

Gandi.net で独自ドメインを取得すると、無料でメールサービスが付いてきます。
メールボックスは２個までですが（課金すれば増やせる）、エイリアスを無制限に使える（しかもワイルドカード指定ができる）ので、使いやすいです。
デフォルトで SPF と DKIM が設定されているので、スパム扱いされるリスクも低いです。すばらしい。

せっかくなので、よりメールの安全性を高めるべく、DMARC も設定してみることにしました。

- DMARCとは？ | SendGridブログ   
  https://sendgrid.kke.co.jp/blog/?p=3137
- SPF, DKIM, and DMARC: How to improve the spam reputation of your domain   
  https://kb.mailbox.org/en/private/custom-domains/spf-dkim-and-dmarc-how-to-improve-the-spam-reputation-of-your-domain
- DMARC 詳細仕様-2 | なりすまし対策ポータル ナリタイ   
  https://www.naritai.jp/guidance_record.html

DMARC の設定というのは、実際のところ、DNS サーバの設定に TXT レコードを１個追加するだけです。簡単。

ちなみに、
SPF は "Sender Policy Framework" の略、
DKIM は "DomainKeys Identified Mail" の略、
DMARC は "Domain-based Message Authentication, Reporting & Conformance" の略です。

## 手順

前提条件として、Gandi.net のメールサービスを使って正常にメール送信できることを確認しておく必要があります。
SPF と DKIM の設定が正しく動作していなければなりません。
独自ドメインのメールアドレスから、自分のプロバイダのメールアドレスとか Gmail とかにメールを送信してみて、届いたメールのメールヘッダの中身をチェックします。
具体的には、`Authentication-Results:` ヘッダの値に `dkim=pass` と `spf=pass` という文字列が含まれていることを確認します。
もし、`dkim=fail` とか `spf=softfail` とか書いてあったらダメです。ちなみに、順不同です（メールサーバによって書かれている順番が異なる）。

{% asset_img SS20220311c_mail_header_spf_dkim.png "メールヘッダの Authentication-Results の例" %}

今回試した限りでは Gandi.net のデフォルト設定で問題なかったので、ダメだった場合は、自分でなにか設定を変えてしまったか、Gandi.net のメールサーバの設定が変わってしまったのか、
いずれにしてもがんばって解決してください。

さて、SPF と DKIM の設定に問題が無いことが確認できたら、DMARC の設定をしてみます。
具体的には、Gandi.net で運用してもらっている DNS サーバの設定を変更することになります（DMARC の設定を追加します）。

Gandi.net にログインして、DNS サーバの設定（「DNSレコード」）を開きます。

{% asset_img SS20220311a_Gandi_admin_page.png "Gandi.net の管理画面" %}

レコード一覧を見ると、SPF と DKIM については最初から設定されていることがわかります。

{% asset_img SS20220311b_Gandi_dns_spf_dkim.png "SPF と DKIM の設定がすでにされている図" %}

ここにひとつ、TXT レコードを追加してあげます。
ページ右上の「レコードを追加」ボタンを押すと「DNSレコードを追加」画面が開くので、テキストを入力します。
「タイプ」は `TXT` を選択します。
「レコード名」には `_dmarc` と入力します。
「テキスト値」には DMARC の設定を書きます。書き方は上記の DMARC 関連リンクを参考にしてください。
下記スクリーンショットは、あくまでも Seaoak のドメインの設定例なので、**そのまま同じ設定を入力してはいけません**。
少なくとも `rua` フィールドの値は自分のドメインのメールアドレスに変える必要があります。

{% asset_img SS20220311d_Gandi_dns_add_record.png "「DNSレコードを追加」の画面" %}

TTL とそのユニットについては、変えなくていいハズ（設定を間違えた場合を考えると短くしたほうがいいのかしら？）。
入力できたら、最後に「設定」ボタンを押すと、**即座に** DNS サーバの設定が更新されます。
DNS レコード一覧を見ると、ちゃんと `_dmarc` の行が追加されていることが確認できます。

{% asset_img SS20220311e_Gandi_dns_dmarc.png "レコード追加後の DNS レコード一覧の画面" %}

ためしに、手元の Windows PC で DNS を引いてみます。
Windows に最初から入っている `nslookup` コマンドを使います。
TXT レコードを指定するために `set type=txt` と入力して、それから `_dmarc.ドメイン名` と入力すると、上で設定した DMARC レコードが表示されるハズです。

{% asset_img SS20220311f_nslookup.png "nslookup を実行してみた例" %}

もし、「～を見つけられません: Non-existent domain」とか言われてしまった場合は、
独自ドメインの DNS 情報がどこかの DNS サーバにキャッシュされてしまっています。
Gandi.net の DNS サーバ（権威サーバ）に設定した情報が反映されるまでしばらく時間をおいてから、再実行してみましょう。
最悪でも翌日になれば変更が反映されるハズです。

`nslookup` コマンドで確認できたら、忘れずに、DMARC の分析レポート (rua) の宛先に指定したメールアドレスで、ちゃんとメールを受信できるようにしておきます。
Gandi.net のメールボックスのエイリアスに `dmac*` とか指定しておけば OK でしょう。
ちなみに、送られてくる分析レポートメールには .zip ファイルが添付されていて、その中身は XML テキストです。
人間には解読できないので、てきとうなクラウドサービスとかを使うのが良さそうですね。

- DMARC SaaS Platform - Best DMARC Solution for Businesses 2022   
  https://www.valimail.com

最後に、DMARC の動作確認をします。
独自ドメインのメールアドレスから（Gandi.net のメールサービスを使って） Gmail とかにメールを送信してみます。
そのメールが無事に受信できたら、受信したメールのメールヘッダをチェックします。
`Authentication-Results:` ヘッダの値に `dmarc=pass` という文字列が含まれていれば成功です。
このとき、`spf=pass` と `dkim=pass` も含まれているハズです。

{% asset_img SS20220311g_mail_header_dmarc.png "DMARC 設定後のメールヘッダの Authentication-Results の例" %}

以上で、DMARC の導入ができました。おつかれさまでした。

## おまけ： .dev ドメインについて

ちなみに蛇足ですが、今回 .dev ドメインを選んだのは、ドメイン丸ごと HSTS が設定されていてセキュリティを重視している点が好みだったからです
（HSTS というのは、HTTP 接続しようとするとブラウザが強制的に HTTPS 接続に切り替えてくれるしくみです）。
正直、.io ドメインとどちらにするか迷ったのですが、費用が .io ドメインの半額以下ですし、
[２文字 TLD （国や地域に割り振られている TLD）は管理体制に不安があるなんて噂](https://gigazine.net/news/20171113-io-domain/)もあるので、.dev ドメインにしました。
なお、HSTS が設定されている副作用として、Gandi.net がデフォルトで提供しているウェブリダイレクト機能を使えない、というデメリットもあります
（HTTPS 接続をリダイレクトするためにはリダイレクトサーバに SSL サーバ証明書が必要になるからですね）。

- .DEV ドメイン名 - Gandi.net   
  https://www.gandi.net/ja/domain/tld/dev
- .IO ドメイン名 - Gandi.net   
  https://www.gandi.net/ja/domain/tld/io
- 「.io」ドメインを製品版で採用してはいけない理由 - GIGAZINE   
  https://gigazine.net/news/20171113-io-domain/
- Strict-Transport-Security - HTTP | MDN   
  https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/Strict-Transport-Security
