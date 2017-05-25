---
title: VPS に VPN サーバをたてて iPhone からアクセス（第4回）
date: 2017-05-10 14:04:56
updated: 2017-05-10 14:04:56
tags:
 - VPN
 - SoftEtherVPN
---

レンタル VPS で VPN サーバを動かして iPhone からのネットアクセスをセキュアにする（ついでに自宅 LAN にリモートアクセスできるようにする）というお話の第4回です。今回は iPhone から SoftEther VPN Server に OpenVPN 接続するお話です。

前回の記事で、iPhone から L2TP/IPsec 接続できるようになりましたが、iPhone の回線が無線 LAN (Wi-Fi) と 4G LTE の間で切り替わったりすると、VPN 接続が切れてしまうことがありました。そのまま気づかずに iPhone を使ってしまうと、暗号化されていない状態で通信してしまいます。ちょっと調べてみると、iPhone の OpenVPN クライアントアプリは自動的に再接続してくれたりするみたいなので、試してみることにしました。

## OpenVPN とは

OpenVPN は、オープンソースの VPN ソフトウェアです。マルチプラットフォーム対応で、安全性も高いようです。

- 公式サイト   
  https://openvpn.net
- OpenVPN.JP | OpenVPN日本語情報サイト   
  https://www.openvpn.jp
- OpenVPNとは   
  https://www.openvpn.jp/introduction/
- yamata::memo: OpenVPNをお勧めできる6つの理由   
  https://yamatamemo.blogspot.jp/2013/04/openvpn6.html
- PPTP vs L2TP/IPSec vs OpenVPN vs IKEv2 - Tech Beans   
  http://soymsk.hatenablog.com/entry/2016/10/05/234551
- FAQ – OpenVPN Community   
  https://community.openvpn.net/openvpn/wiki/FAQ
- OpenVPN Connect iOS FAQ   
  https://docs.openvpn.net/docs/openvpn-connect/openvpn-connect-ios-faq.html

## サーバ側の設定

SoftEther VPN Server には OpenVPN クライアントからの接続を受け付ける機能があるので、それを利用します。OpenVPN クライアント設定用ファイルを自動生成してくれるので、とても簡単です。

- OpenVPN の置換 - SoftEther VPN プロジェクト   
  https://ja.softether.org/4-docs/2-howto/7.Replacements_of_Legacy_VPNs/2.Replacements_of_OpenVPN
- OpenVPN プロトコルのサポート - SoftEther VPN プロジェクト   
  [link](https://ja.softether.org/1-features/1._%E6%A5%B5%E3%82%81%E3%81%A6%E5%BC%B7%E5%8A%9B%E3%81%AA_VPN_%E6%8E%A5%E7%B6%9A%E6%80%A7#OpenVPN_.E3.83.97.E3.83.AD.E3.83.88.E3.82.B3.E3.83.AB.E3.81.AE.E3.82.B5.E3.83.9D.E3.83.BC.E3.83.88)

OpenVPN ではデフォルトで UDP 1194番ポートを使用しますが、SoftEther VPN Server はすべてのリスナーポートで OpenVPN クライアントからの接続を受けられるので、今回は TCP 443番ポートをそのまま使用します。UDP 1194番ポートは無効化します。

Windows PC で「SoftEther VPN サーバー管理マネージャ」を使って設定する場合は、OpenVPN 機能を有効にして、UDP ポート番号の欄を空欄にします。また、「OpenVPN クライアント用のサンプル設定ファイルを生成」ボタンを押して zip ファイルをダウンロードしておきます。

{% asset_img SS_GUI_OpenVPN.png "「SoftEther VPN サーバー管理マネージャ」での設定例" %}

vpncmd を使って設定する場合は、[公式マニュアルの OpenVpnEnable コマンドの説明](http://ja.softether.org/4-docs/1-manual/6/6.3#6.3.74_.22OpenVpnEnable.22:_OpenVPN_.E4.BA.92.E6.8F.9B.E3.82.B5.E3.83.BC.E3.83.90.E3.83.BC.E6.A9.9F.E8.83.BD.E3.82.92.E6.9C.89.E5.8A.B9.E5.8C.96_.2F_.E7.84.A1.E5.8A.B9.E5.8C.96)を参照して、以下のように行います。

```
VPN Server>OpenVpnEnable yes /PORTS:none
VPN Server>OpenVpnMakeConfig vpn33_openvpn_config_20170510d.zip
```

カレントディレクトリにクライアント設定用ファイル（zip ファイル）ができているはずです。

## クライアント設定用ファイルの作成

上記の手順で得られた zip ファイルを展開すると、Readme ファイルの他に、拡張子 `.opvn` のファイルが2個できるはずです。このうち、`***_openvpn_remote_access_l3.opvn` のほうを使います。

```
vpn33_openvpn_remote_access_l3.ovpn
vpn33_openvpn_site_to_site_bridge_l2.ovpn
readme.pdf
readme.txt
```

まず、念のため、ファイルのコピーを作成して、わかりやすい名前を付けておきます（拡張子は変えないでください）。たぶんファイル名には日本語を使わないほうが安全だと思います。このコピーのほうを使います。ファイル名は仮に `vpn33_hub01.opvn` とします。

ファイル `vpn33_hub01.opvn` をテキストエディタで開いて編集します：

- プロトコルを「`udp`」から「`tcp`」に変更。
- 接続先を IP アドレスから「`vpn33.example.com`」に変更。
- ポート番号を「`1194`」から「`443`」に変更。

編集後に diff をとると以下のようになります：

```bash
$ diff vpn33_openvpn_remote_access_l3.ovpn vpn33_hub01.ovpn
41c41
< proto udp
---
> proto tcp
62c62
< remote 192.0.2.33 1194
---
> remote vpn33.example.com 443
$
```

## iPhone に OpenVPN クライアントアプリをインストール

iOS 用の OpenVPN クライアントアプリ「OpenVPN Connect」を App Store からインストールします。無料です。

- OpenVPN Technologies「OpenVPN Connect」   
  https://appsto.re/jp/nVhmJ.i

{% asset_img SS_app_store.png "App Store のページ" %}

インストールしたら、「設定」アプリで「OpenVPN」を選択して、設定を行います。

{% asset_img SS_app_setting.png "OpenVPN アプリの設定例" %}

なお、この設定画面で「Connect via」欄を「Wi-Fi only」に変更すると、Wi-Fi と 4G LTE の自動切り替えがうまくいかないことがありました（Wi-Fi の電波が届かなくなっても 4G LTE に切り替わらず通信できない状態になる）。原因がわからないので、とりあえず「Any network」に設定しています。

## クライアント設定用ファイルを iPhone に転送

作成しておいたクライアント設定用ファイル `vpn33_hub01.opvn` を、iTunes 経由で iPhone に転送します。

1. iTunes で iPhone 画面を開く。
1. ウインドウ左側に縦に並んでいるメニュー項目から「App」を選択する。   
  {% asset_img SS_iTunes_01.png "iTunes のスクリーンショットその１" %}
1. iPhone のホーム画面のスクリーンショットが並んでいるフレームが右側に表示されるので、下方向にスクロールする。   
  {% asset_img SS_iTunes_02.png "iTunes のスクリーンショットその２" %}
1. 「ファイル共有」のところにアプリが並んでいるので、その中から「OpenVPN」を選択する。   
  {% asset_img SS_iTunes_03.png "iTunes のスクリーンショットその３" %}    
  {% asset_img SS_iTunes_04.png "iTunes のスクリーンショットその４" %}
1. 右側にある「ファイルを追加」ボタンを押して、開いたダイアログでクライアント設定用ファイルを選択する。    
  {% asset_img SS_iTunes_05.png "iTunes のスクリーンショットその４" %}
1. iPhone と同期を行う。 ←これは不要かも？

## OpenVPN クライアントアプリで接続設定する

iPhone で作業します。

1. すでに VPN 接続中の場合は切断する（設定を削除する必要はありません）。
1. OpenVPN クライアントアプリを起動する。
1. 「新しい profile があるよ」と言われるのでインポートを選択する。   
  {% asset_img SS_app_import.png "OpenVPN アプリのスクリーンショットその１" %}
1. Profile 設定画面になる。   
  {% asset_img SS_profile_init.png "OpenVPN アプリのスクリーンショットその２" %}
1. ユーザ名として「`yamada@hub01`」と入力する。
1. パスワードとして仮想 HUB に設定した「`K8nhrGJHHe98tCck4NGA`」を入力する。
1. Save を ON にする。   
  {% asset_img SS_profile_done.png "OpenVPN アプリのスクリーンショットその３" %}
1. 「Disconnected」欄のすぐ下のスイッチを ON にすると接続開始。
1. 「Connected」と表示されれば接続成功。   
  {% asset_img SS_connected.png "OpenVPN アプリのスクリーンショットその４" %}
1. 画面左上の電波状況アイコンの隣に「VPN」アイコンが表示されていることを確認する。   
  {% asset_img SS_header_VPN_icon.png "VPN アイコン表示例" %}

これで VPN を経由して普通にインターネットにアクセスできるはずです。Safari や Twitter や LINE などが使えることを確認してください。

## サーバ側のログを確認

L2TP/IPsec 接続のときと同様、vpnserver のログファイルが更新されているはずです。

```bash
$ less server_log/vpn_20170510.log
```

iPhone から OpenVPN でアクセスしたログが表示されるはずです。仮想 HUB「`hub01`」にユーザ名「`yamada`」で接続しているはずです。

```
2017-05-10 12:58:04.862 OpenVPN モジュール: OpenVPN サーバーモジュールを起動しました。
2017-05-10 12:58:05.127 [HUB "hub01"] コネクション "CID-4723" (IP アドレス 203.0.113.111, ホスト名 203.0.113.111.example.com, ポート番号 61449, クライアント名 "OpenVPN Client", バージョン 4.22 ビルド 9634) が仮想 HUB への接続を試行しています。提示している認証方法は "外部サーバー認証" でユーザー名は "yamada" です。
2017-05-10 12:58:05.127 [HUB "hub01"] コネクション "CID-4723": ユーザー "yamada" として正しく認証されました。
2017-05-10 12:58:05.127 [HUB "hub01"] コネクション "CID-4723": 新しいセッション "SID-yamada-[OPENVPN_L3]-1455" が作成されました。(IP アドレス 203.0.113.111, ポート番号 61449, 物理レイヤのプロトコル: "Legacy VPN - OPENVPN_L3")
2017-05-10 12:58:05.127 [HUB "hub01"] セッション "SID-YAMADA-[OPENVPN_L3]-1455": パラメータが設定されました。最大 TCP コネクション数 1, 暗号化の使用 はい, 圧縮の使用 いいえ, 半二重通信の使用 いいえ, タイムアウト 20 秒
2017-05-10 12:58:05.127 [HUB "hub01"] セッション "SID-YAMADA-[OPENVPN_L3]-1455": VPN Client の詳細: (クライアント製品名 "OpenVPN Client", クライアントバージョン 422, クライアントビルド番号 9634, サーバー製品名 "SoftEther VPN Server (64 bit) (Open Source)", サーバーバージョン 422, サーバービルド番号 9634, クライアント OS 名 "OpenVPN Client", クライアント OS バージョン "-", クライアントプロダクト ID "-", クライアントホスト名 "", クライアント IP アドレス "203.0.113.111", クライアントポート番号 61449, サーバーホスト名 "192.0.2.33", サーバー IP アドレス "192.0.2.33", サーバーポート番号 443, プロキシホスト名 "", プロキシ IP アドレス "0.0.0.0", プロキシポート番号 0, 仮想 HUB 名 "hub01", クライアントユニーク ID "12345678901234567890ABCDEF123456")
2017-05-10 12:58:05.906 [HUB "hub01"] SecureNAT: DHCP エントリ 1596 が作成されました。MAC アドレス: 12-34-56-78-90-AB, IP アドレス: 192.168.233.10, ホスト名: , 有効期限: 7200 秒
2017-05-10 12:58:05.906 [HUB "hub01"] セッション "SID-SECURENAT-1": このセッション上のホスト "00-AC-F5-3B-F5-5B" (192.168.233.1) の DHCP サーバーは、別のセッション "SID-YAMADA-[OPENVPN_L3]-1455" 上のホスト "12-34-56-78-90-AB" に対して新しい IP アドレス 192.168.233.10 を割り当てました。
2017-05-10 12:58:05.906 OpenVPN セッション 1 (203.0.113.111:61449 -> 192.0.2.33:443) チャネル 0: チャネルが確立状態になりました。
2017-05-10 12:58:05.906 OpenVPN セッション 1 (203.0.113.111:61449 -> 192.0.2.33:443) チャネル 0: クライアントの IP アドレスおよびその他の IP ネットワーク情報の設定が完了しました。クライアント IP アドレス: 192.168.233.10, サブネットマスク: 255.255.255.0, デフォルトゲートウェイ: 192.168.233.1, DNS サーバー 1: 192.168.233.1, DNS サーバー 2: , WINS サーバー 1: , WINS サーバー 2:
2017-05-10 12:58:05.906 OpenVPN セッション 1 (203.0.113.111:61449 -> 192.0.2.33:443) チャネル 0: 応答オプション文字列の全文: "PUSH_REPLY,ping 3,ping-restart 10,ifconfig 192.168.233.10 192.168.233.14,dhcp-option DNS 192.168.233.1,route-gateway 192.168.233.14,redirect-gateway def1"
```
