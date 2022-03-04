---
title: VPS に VPN サーバをたてて iPhone からアクセス（第2回）
date: 2017-05-10 14:02:19
updated: 2017-05-10 14:02:19
tags:
 - VPN
 - SoftEtherVPN
---

レンタル VPS で VPN サーバを動かして iPhone からのネットアクセスをセキュアにする（ついでに自宅 LAN にリモートアクセスできるようにする）というお話の第2回です。今回は SoftEther VPN Server の導入編です。

## SoftEther VPN とは

SoftEther VPN は、オープンソースで高機能な VPN ソフトウェアです。独自の VPN 通信方式を実装していて、様々なネットワーク構成に柔軟に対応しています。また、独自の Windows/Linux クライアントはもちろん、L2TP/IPsec や MS-SSTP や OpenVPN など、多くのクライアントからの接続が可能です。

- SoftEther VPN プロジェクト   
  https://ja.softether.org
- SoftEther VPN とは   
  https://ja.softether.org/4-docs/1-manual/1/1.1
- SoftEther VPN の活用例   
  https://ja.softether.org/4-docs/2-howto
- GitHub リポジトリ   
  https://github.com/SoftEtherVPN/SoftEtherVPN/

## SoftEther VPN を選んだ理由

- Layer 2 VPN なので LAN 専用のホーム機器にもリモートアクセス可能。
- ファイアウォール貫通機能が異様に強い。
- クラウド上の Linux VPS (Ubuntu 14.04 LTS) で VPN サーバを動かせる。
  - プログラムとして x86_64 Linux（カーネルが古い）で動作可能。
  - VPS が設置されているネットワークに迷惑をかけない。   
    （構築した VPN がサーバの実ネットワークから切り離されている）
- iPhone からの接続が可能。
  - iOS 標準機能の L2TP/IPsec が使える。
  - L2TP/IPsec がダメでも OpenVPN が使える。
- 自宅の Windows PC から接続可能。
- 自宅の Windows PC をブリッジとして自宅 LAN にリモートアクセス可能。
- 将来的に Raspberry Pi を買えばブリッジとして使える。
- VPN サーバをユーザモードで動かせる。 ★すごくうれしい★
- NAT 機能と DHCP サーバ機能を内蔵していて簡単に使える。
- 待ち受けポート番号を変更できる（デフォルトは避けたい）。
- Windows GUI アプリからでも SSH コマンドラインからでも設定・管理が可能。
- オープンソースなので好きに改造できる。
- 日本語のマニュアルが充実している。
- 国産のプロダクトであり、応援したい。

ちなみに、ちょっと気になる点もあります：

- TLS 1.2 に対応していない（TLS 1.0 のみ）。
- 使用できる暗号スイートが古い（弱い）。
- SHA-1 しか選べない（SHA-256 にしたい）。 
- 証明書の鍵が RSA 2048bit までしか選べない（弱い）。
- 証明書の SAN フィールドに対応していない（廃止された CN フィールドを見てる）。
- 日本語のログを吐く（検索や加工がしにくい）。
- テストスクリプトが公開されていない（改造してもテストできない）。

## SoftEther VPN Server のダウンロード

ダウンロードするアーカイブファイルの URL は公式サイト参照：
https://ja.softether.org/5-download

最新版 (beta) と安定版 (RTM) が異なる場合は、お好きな方を選んでください。

表示されたリンクの URL をコピペしてダウンロードします：

```bash-prompt
$ cd softether
$ curl -O http://jp.softether-download.com/files/softether/v4.20-9608-rtm-2016.04.17-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.20-9608-rtm-2016.04.17-linux-x64-64bit.tar.gz
$ mkdir softether-vpnserver-v4.20-9608-rtm-2016.04.17-linux-x64-64bit
$ cd softether-vpnserver-v4.20-9608-rtm-2016.04.17-linux-x64-64bit
$ tar xvfz ../softether-vpnserver-v4.20-9608-rtm-2016.04.17-linux-x64-64bit.tar.gz
```

セキュリティ関係のソフトウェアなのに配布サーバが HTTPS 化されてないのが残念。不安な人は GitHub からソースファイルをダウンロードしてビルドしましょう。

## 今回のサーバ環境

今回のインストール先は、クラウド上のレンタル VPS です。

```
仮想化方式 : OpenVZ （Linux カーネルが更新できない！）
CPU : Intel Xeon
Memory : 2GB
OS : Ubuntu 14.04 LTS (x86_64)
グローバル IP アドレス : 固定で2個（IPv6 ありの仮想インタフェース）
```

2個あるグローバル IP アドレスは、いずれも FQDN で DNS lookup できます。ただし、CNAME レコードで DNS に登録しているため、逆引きはその FQDN とは異なります。今回は、2個あるグローバル IP アドレスのうち、「default route でない方」を SoftEther VPN Server で使用します。文中では、仮に、以下の値を使用します：

```
Interface: vnet1
IPv4: 192.0.2.33/24
IPv6: 2001:db8::2:33/64
FQDN: vpn33.example.com
```

なお、ほんとうは Docker で SoftEther VPN Server を動かしてみたかったのですが、Linux カーネルが古くて Docker は使えませんでした。上記のとおり仮想化方式が OpenVZ なので、カーネルの更新ができないのです。残念！

## SoftEther VPN Server のインストール

まず、公式マニュアルを参照：

- 7.3 Linux へのインストールと初期設定 - SoftEther VPN プロジェクト   
  https://ja.softether.org/4-docs/1-manual/7/7.3

今回は SoftEther VPN Server をユーザモードで動かすので、公式マニュアルの「7.3.6 VPN Server の配置」以降の作業はやりません（make を実行するだけです）。

```bash-prompt
$ cd vpnserver
$ nice -19 make
```

無事に make できたら、実行に必要なファイルだけ手動でコピーします。

```bash-prompt
$ mkdir ../../bin
$ cp -p hamcore.se2 vpncmd vpnserver ../../bin
$ cd ../../bin
```

ここでひとつ、おまじないが必要です。

SoftEther VPN Server はデフォルトで TCP 443番ポート（https プロトコル用のポート）で接続を待ち受けます（bind します）。また、iPhone からの接続に L2TP/IPsec を使う場合、UDP 500番ポートと UDP 4500番ポートも bind します。Linux（というか UNIX 全般）では1024番未満のポートを bind するためには「特権」(capabilities) が必要です。iptables で1024番以上のポートにリダイレクトする、という抜け道もありますが、SoftEther VPN Server で L2TP/IPsec の待ち受けポート番号を変える方法がわからないので、今回は使えません（参考記事：「{% post_link how-to-listen-privileged-ports %}」）。Docker を使えればポートマッピングでなんとかなったかもしれませんが。

今回は、Linux の "File Capabilities" 機能を利用して、実行ファイル vpnserver に CAP_NET_BIND_SERVICE 権限を付与します。これにより、root 権限がなくても、この実行ファイルを実行したときに限り、1024番未満のポートを bind できるようになります。ついでに、念のため、ディレクトリ丸ごと Owner を別のユーザに変更して、実行ファイルを書き換えられないようにしておきます。

- 権限を最小化するLinuxカーネルケーパビリティ － ＠IT   
  http://www.atmarkit.co.jp/fsecurity/rensai/lids03/lids01.html
- Man page of CAPABILITIES   
  https://linuxjm.osdn.jp/html/LDP_man-pages/man7/capabilities.7.html

```bash-prompt
$ sudo chmod -R a-w .
$ sudo chown -R nobody .
$ sudo chgrp -R nogroup .
$ sudo setcap CAP_NET_BIND_SERVICE+eip vpnserver
```

もし、setcap コマンドが無いと怒られたら、`libcap2-bin` パッケージをインストールしてください。CentOS などの RPM 系では `libcap` パッケージらしいです。（[参考ページ](http://www.usupi.org/sysad/183.html)）

```bash-prompt
$ sudo apt-get install libcap2-bin
```

最後に、vpnserver を実行するディレクトリ（この配下にログファイルなどが作られる）に移動して、上記ファイルへのシンボリックリンクを作成します。

```bash-prompt
$ mkdir ../run
$ cd ../run
$ rm -f hamcore.se2 vpncmd vpnserver
$ ln -s ../bin/hamcore.se2
$ ln -s ../bin/vpncmd
$ ln -s ../bin/vpnserver
```

初期状態では SoftEther VPN Server の管理者パスワードが設定されていないので、まだファイアウォール (iptables) に穴を開けてはいけません。ローカル・ループバック通信は iptables でデフォルトで許可されているはずなので、次に説明する初期設定は可能なはずです。

## SoftEther VPN Server の初期設定

- 7.4 初期設定 - SoftEther VPN プロジェクト   
  https://ja.softether.org/4-docs/1-manual/7/7.4

上記の公式マニュアルでは、vpnserver を起動してから**「できるだけ早く」**VPN サーバー管理マネージャで接続して管理者パスワードを変更するように、と書かれていますが、**セキュリティ関係のソフトウェアでそんな危ういことをしてはいけません。**

まず、vpnserver が初期状態で bind するすべてのポートを、ファイアウォール (iptables と ip6tables) がブロックしていることを確認します。

- 443/tcp
- 992/tcp
- 1194/tcp
- 5555/tcp

次に、vpnserver を起動します。起動するとすぐにコマンドプロンプトに戻ってきます。

```bash-prompt
$ date && nice -10 ./vpnserver start
```

続いて、vpncmd を実行して初期設定を開始します。

```bash-prompt
$ ./vpncmd localhost:443 /SERVER
```

1. 管理者パスワードを設定する。
1. デフォルトのリスナーポート「992番」を Disable する。
1. デフォルトのリスナーポート「1194番」を Disable する。
1. デフォルトのリスナーポート「5555番」を Disable する。
1. SSL 通信で使用する暗号化アルゴリズムを一番強い「DHE-RSA-AES128-SHA」に変更する。
1. 「インターネット接続の維持機能」を Disable する。
1. 「VPN Azure 中継サービス」を利用しないようにする。
1. デフォルトで存在している仮想 HUB「DEFAULT」を削除する。
1. ランダムに初期化されたサーバ証明書をファイルとして保存しておく。
1. SoftEther VPN プロジェクトが提供している Dynamic DNS (DDNS) サービスを利用しないようにする。

最後の項目だけは vpncmd では設定できません。それ以外の項目を vpncmd 上で設定します。

```
VPN Server>ServerPasswordSet
VPN Server>ListenerList
VPN Server>ListenerDisable 992
VPN Server>ListenerDisable 1194
VPN Server>ListenerDisable 5555
VPN Server>ServerCipherGet
VPN Server>ServerCipherSet DHE-RSA-AES128-SHA
VPN Server>KeepDisable
VPN Server>VpnAzureSetEnable no
VPN Server>HubDelete DEFAULT
VPN Server>ServerCertGet ./cert.pem
VPN Server>exit
```

なお、今回は接続性を優先して待ち受けポートを443番（HTTPS と同じ）にしていますが、セキュリティを優先するなら別のポートにしたほうが良いです。1024番以上のポートを使えば、前述の「おまじない」（Capabilities 付与）も不要になります（ただし iPhone から L2TP/IPsec 接続する場合は UDP 500番ポートを使うので「おまじない」必須）。

vpncmd が終了したら、vpnserver も停止させます。

```bash-prompt
$ ./vpnserver stop
```

続いて、設定ファイル `vpn_server.config` をテキストエディタで開いて、直接編集します。[公式マニュアルの "DynamicDnsGetHostname" の項](https://ja.softether.org/4-docs/1-manual/6/6.3#6.3.82_.22DynamicDnsGetStatus.22:_.E3.83.80.E3.82.A4.E3.83.8A.E3.83.9F.E3.83.83.E3.82.AF_DNS_.E6.A9.9F.E8.83.BD.E3.81.AE.E7.8F.BE.E5.9C.A8.E3.81.AE.E7.8A.B6.E6.85.8B.E3.81.AE.E5.8F.96.E5.BE.97)を参照して、Dynamic DNS を無効化します。

最後に、設定ファイル `vpn_server.config` を別の機器（USB メモリとか）にバックアップしておきます。ただし、このファイルには SoftEther VPN Server の秘密鍵が含まれているので、取り扱いには注意しましょう。

## ファイアウォールに穴を開ける

TCP 443番ポートのみ待ち受け可能にします。

```bash-prompt
$ sudo iptables -A INPUT -i vnet1 -d '192.0.2.33' -p tcp --dport 443 -j ACCEPT
$ sudo iptables -L -vn
$ sudo ip6tables -A INPUT -i vnet1 -d '2001:db8::2:33 ' -p tcp --dport 443 -j ACCEPT
$ sudo ip6tables -L -vn
$ sudo /etc/init.d/iptables-persistent save
```

もし、`iptables-persistent` が無いと怒られたら、`iptables-persistent` パッケージをインストールしてください。

```bash-prompt
$ sudo apt-get install iptables-persistent
```

vpnserver を起動して、ちゃんと TCP 443番ポートを listen しているか netstat コマンドで確認しておきます。

```bash-prompt
$ date && nice -10 ./vpnserver start
$ netstat -antu
```

## 仮想 HUB の新規作成

iPhone からネットアクセスする際に使う仮想 HUB を新規作成します。

- 仮想 HUB の名前は `hub01` とする。
- iPhone 側のユーザ名は `yamada` とする。
- ユーザ `yamada` のパスワードは `K8nhrGJHHe98tCck4NGA` とする（乱数生成）。
- 仮想 HUB 管理パスワードは不要なので設定しない。
- SecureNAT 機能を有効化する（デフォルトで DHCP サーバ機能も有効になる）。
- 仮想 HUB で使用するサブネットは `192.168.223.0/24` とする（他とかぶらなさそうなプライベートアドレスを適当に選ぶ）。

実際の作業は vpncmd で行います。もちろん、Windows PC の「SoftEther VPN サーバー管理マネージャ」でも同様の設定が可能です。

```bash-prompt
$ ./vpncmd localhost:443 /SERVER
```

```
VPN Server>HubCreate hub01
VPN Server>Hub hub01
VPN Server>SetEnumDeny
VPN Server>UserCreate yamada /GROUP:none /REALNAME:none /NOTE:none
VPN Server>UserPasswordSet yamada
K8nhrGJHHe98tCck4NGA
VPN Server>SecureNatStatusGet
VPN Server>SecureNatHostGet
VPN Server>SecureNatHostSet /MAC:none /IP:192.168.223.1 /MASK:255.255.255.0
VPN Server>NatGet
VPN Server>DhcpGet
VPN Server>DhcpSet /START:192.168.223.10 /END:192.168.223.200 /MASK:255.255.255.0 /EXPIRE:86400 /GW:192.168.223.1 /DNS:192.168.223.1 /DNS2:none /DOMAIN:none /LOG:yes
VPN Server>SecureNatEnable
VPN Server>SecureNatStatusGet
```

iPhone から接続するときには、ユーザ名として「`yamada@hub01` 」を、パスワードとして「`K8nhrGJHHe98tCck4NGA`」を、それぞれ使用することになります。

なお、仮想 HUB を新規に作成したときは、「SoftEther VPN サーバー管理マネージャ」の仮想 HUB のプロパティ設定ウインドウでチェックボックス「匿名ユーザーに対してこの仮想 HUB を列挙しない」に必ずチェックを入れましょう。あるいは、vpncmd で仮想 HUB 設定に遷移して `SetEnumDeny` コマンドを実行しても同じです（上記の設定例でも実行しています）。

## より安全に運用するには

1. Windows PC 上の GUI アプリ「SoftEther VPN サーバー管理マネージャ」を使わずに vpncmd だけで管理できるなら、管理者ログインを VPN サーバ内部からのみに制限できます。リモートから SoftEther VPN Server に直接接続して設定することが不可能になるので、より安全になります。もちろん、SoftEther VPN Server を動かしているサーバに SSH ログインできれば、vpncmd を使ってリモートから管理できます。

    具体的には、SoftEther VPN Server のリモート管理接続元 IP アドレスとして `127.0.0.1` と `::1` だけを許可します。設定方法は[公式マニュアルの「3.3.18 IP アドレスによるリモート管理接続元の制限」](https://ja.softether.org/4-docs/1-manual/3/3.3#3.3.18_IP_.E3.82.A2.E3.83.89.E3.83.AC.E3.82.B9.E3.81.AB.E3.82.88.E3.82.8B.E3.83.AA.E3.83.A2.E3.83.BC.E3.83.88.E7.AE.A1.E7.90.86.E6.8E.A5.E7.B6.9A.E5.85.83.E3.81.AE.E5.88.B6.E9.99.90)を参照してください。

1. 万が一に備えて、vpnserver を実行するユーザを新たに作って SoftEther VPN Server 専用のユーザにすることをオススメします。

    SoftEther VPN Server のダウンロードや make などは普段使っているユーザで行い、生成された実行ファイル `vpnserver` とライブラリファイル `hamcore.se2` を実行用ユーザのホームディレクトリ配下にコピーすれば、vpnserver を実行できます。実行用ユーザに GitHub などへのアクセス権を与える必要はありません。

    管理コマンド vpncmd は誰でも（vpnserver を実行しているユーザ以外でも）使えるので、vpnserver 実行用ユーザはそれこそ「ログインできないユーザ」（ログインシェルが `/bin/false` や `/usr/sbin/nologin` になっているユーザ）でも問題ありません。というか、ログインできないように設定することをオススメします。

    vpnserver 実行用ユーザは、`sudo` できないユーザにしておきましょう。具体的な条件は `/etc/sudoers` の設定に依存しますが、デフォルトならば「グループ `sudo` に属さないユーザ」にしておけば大丈夫です。

    ユーザ root が存在するシステムでは、vpnserver 実行ユーザは root への `su` ができないユーザにしておきましょう。たとえば、グループ `wheel` に属しているユーザは避けましょう。
