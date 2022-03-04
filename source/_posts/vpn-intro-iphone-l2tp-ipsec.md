---
title: VPS に VPN サーバをたてて iPhone からアクセス（第3回）
date: 2017-05-10 14:03:24
updated: 2017-05-10 14:03:24
tags:
 - VPN
 - SoftEtherVPN
---

レンタル VPS で VPN サーバを動かして iPhone からのネットアクセスをセキュアにする（ついでに自宅 LAN にリモートアクセスできるようにする）というお話の第3回です。今回は iPhone から SoftEther VPN Server に L2TP/IPsec で接続するお話です。

## まずは公式マニュアル

- SoftEther VPN Server での L2TP/IPsec 設定ガイド   
  https://ja.softether.org/4-docs/2-howto/L2TP_IPsec_Setup_Guide

## サーバ側の設定

第2回の記事にも書きましたが、サーバ環境は次のとおりです：

```
Interface: vnet1
IPv4: 192.0.2.33/24
IPv6: 2001:db8::2:33/64
FQDN: vpn33.example.com
```

まず、ファイアウォールに穴をあけます。UDP 500番ポートと、UDP 4500番ポートで、待ち受けできるようにします。

```bash-prompt
$ sudo iptables -A INPUT -i vnet1 -d '192.0.2.33' -p udp --dport 500 -j ACCEPT
$ sudo iptables -A INPUT -i vnet1 -d '192.0.2.33' -p udp --dport 4500 -j ACCEPT
$ sudo iptables -L -vn
$ sudo ip6tables -A INPUT -i vnet1 -d '2001:db8::2:33' -p udp --dport 500 -j ACCEPT
$ sudo ip6tables -A INPUT -i vnet1 -d '2001:db8::2:33' -p udp --dport 4500 -j ACCEPT
$ sudo ip6tables -L -vn
$ sudo /etc/init.d/iptables-persistent save
```

次に、SoftEther VPN Server で L2TP/IPsec 接続を有効化します。

Windows PC 上の「SoftEther VPN サーバー管理マネージャ」でサーバに接続して設定する場合は、次のスクリーンショットのように設定します：

{% asset_img SS_GUI_L2TP_IPsec.png "「SoftEther VPN サーバー管理マネージャ」での設定例" %}

もちろん、vpncmd コマンドを使えばコマンドライン上でも設定できます：

```bash-prompt
$ ./vpncmd localhost:443 /SERVER
VPN Server>IPsecEnable /L2TP:yes /L2TPRAW:no /ETHERIP:no /PSK:Ppz6o5x9J /DEFAULTHUB:hub01
```

なお、PSK (Pre-Shared-Key) には35文字くらいのランダムな英数字を指定するのが良さそうです。[とある解説記事](https://blog.webernetz.net/2015/01/19/considerations-about-ipsec-pre-shared-keys-psks/)によれば「30～40文字で英数字のみ」が推奨らしいです。ただし、[SoftEther VPN 公式マニュアルの `IPsecEnable` コマンドの説明](https://ja.softether.org/4-docs/1-manual/6/6.3#6.3.69_.22IPsecEnable.22:_IPsec_VPN_.E3.82.B5.E3.83.BC.E3.83.90.E3.83.BC.E6.A9.9F.E8.83.BD.E3.81.AE.E6.9C.89.E5.8A.B9.E5.8C.96_.2F_.E7.84.A1.E5.8A.B9.E5.8C.96)には「Google Android 4.0 にはバグがあり、PSK の文字数が 10 文字を超えた場合は VPN 通信に失敗することがあります。そのため、PSK の文字数は 9 文字以下にすることを推奨します。」と書かれているので、古い Android を使いたい人は9文字推奨です（上記の例はこれ）。

参考：

- SoftEther VPN 公式マニュアルの `IPsecEnable` コマンドの説明   
  [link](https://ja.softether.org/4-docs/1-manual/6/6.3#6.3.69_.22IPsecEnable.22:_IPsec_VPN_.E3.82.B5.E3.83.BC.E3.83.90.E3.83.BC.E6.A9.9F.E8.83.BD.E3.81.AE.E6.9C.89.E5.8A.B9.E5.8C.96_.2F_.E7.84.A1.E5.8A.B9.E5.8C.96)
- What is the Minimum and Maximum length of the IPSec PSK (Pre-Shared Key)   
  https://supportcenter.checkpoint.com/supportcenter/portal?eventSubmit_doGoviewsolutiondetails=&solutionid=sk66660
- Considerations about IPsec Pre-Shared Keys - Blog Webernetz.net   
  https://blog.webernetz.net/2015/01/19/considerations-about-ipsec-pre-shared-keys-psks/

## iPhone 側の設定

iOS 10.3.1 で試しました。

iOS 標準機能で L2TP/IPsec 接続が可能です。アプリのインストールは不要です。VPN 接続の ON/OFF も、標準の「設定」アプリでできます。

{% asset_img SS_L2TP_setting.png "設定画面スクリーンショット" %}

1. 「設定」アプリを起動。
1. 「VPN」を選択。
1. 「VPN構成を追加...」を選択。
  1. 「タイプ」は「L2TP」を選択。
  1. 「説明」欄は「`hub01@vpn33`」とか適当に入力。
  1. 「サーバ」欄には「`vpn33.example.com`」と入力。
  1. 「アカウント」欄には「`yamada@hub01`」と入力。
  1. 「RSA SecureID」は OFF のまま。
  1. 「パスワード」欄には「`K8nhrGJHHe98tCck4NGA`」と入力。
  1. 「シークレット」欄には PSK 「`Ppz6o5x9J`」を入力。
  1. 「すべての信号を送信」は ON のまま。
  1. 「プロキシ」は「OFF」のまま。
  1. 右上の「完了」を押す。
1. 「VPN」画面で、追加した構成を押す（チェックマークが付く）。
1. 「状況」欄が「未接続」となっているでタッチ。
1. 「状況」欄が「接続しています...」となる。
1. VPN 接続に成功すると「状況」欄が「接続中」になる。
1. 画面左上の電波状況アイコンの隣に「VPN」アイコンが表示されていれば完了。

{% asset_img SS_header_VPN_icon.png "VPN アイコン表示例" %}

これで VPN を経由して普通にインターネットにアクセスできるはずです。Safari や Twitter や LINE などが使えることを確認してください。

## サーバ側のログを確認

vpnserver を実行したディレクトリにログファイル用のディレクトリが自動的に作られているはずです。デフォルトでは、自動的に定期的に新しいログファイルに切り替わっていきます。ログファイルは単なる UTF-8 のテキストファイルです。SoftEther VPN Server の言語設定が「日本語」だと、ログも日本語になります。

```bash-prompt
$ less server_log/vpn_20170510.log
```

先ほど iPhone からアクセスしたログが表示されるはずです。仮想 HUB「`hub01`」にユーザ名「`yamada`」で接続しているはずです。

```
2017-05-10 12:05:57.268 [HUB "hub01"] コネクション "CID-4" (IP アドレス 203.0.113.111, ホスト名 203.0.113.111.example.com, ポート番号 1701, クライアント名 "L2TP VPN Client", バージョン 4.20 ビルド 9608) が仮想 HUB への接続を試行しています。提示している認証方法は "外部サーバー認証" でユーザー名は "yamada" です。
2017-05-10 12:05:57.268 [HUB "hub01"] コネクション "CID-4": ユーザー "yamada" として正しく認証されました。
2017-05-10 12:05:57.268 [HUB "hub01"] コネクション "CID-4": 新しいセッション "SID-YAMADA-[L2TP]-2" が作成されました。(IP アドレス 203.0.113.111, ポート番号 1701, 物理レイヤのプロトコル: "Legacy VPN - L2TP")
```
