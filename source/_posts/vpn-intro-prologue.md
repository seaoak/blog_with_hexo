---
title: VPS に VPN サーバをたてて iPhone からアクセス（第1回）
date: 2017-05-10 14:01:25
updated: 2017-05-10 14:01:25
tags:
 - VPN
 - SoftEtherVPN
---

レンタル VPS で VPN サーバを動かして iPhone からのネットアクセスをセキュアにする（ついでに自宅 LAN にリモートアクセスできるようにする）というお話の第1回です。今回は VPN について調べたことなどをご紹介します。具体的な構築作業については次回から。

## まえがき

以前から、外出先で iPhone を使うときのネットアクセスの安全性が気になっていました。4G LTE 回線を使った通信は、まぁ、ちゃんとした通信事業者の専用回線を使っているわけなので、あまり心配していません（HTTP 通信の中身を見て画像データを勝手に圧縮したり、特定の Web サービスとの通信を識別して課金操作したり、特定のプロトコルの通信を遮断したりと、不安要素はありますが）。問題なのは、公衆無線 LAN (Wi-Fi) を使うときです。

最近は HTTPS (SSL/TLS) が普及してきたので Google とか Twitter とか使うぶんにはあまり気にしなくても良いのですが、一般の Web サイトは HTTPS 化されていないことも多いです（特に日本国内の Web サイトは遅れている印象）。あと、DNS は暗号化されていないので、「どこのサーバにアクセスしたか」はバレバレです。アクセスを遮断される可能性や、ニセのサーバに誘導される危険もあります。これに関して DNSSEC は役に立ちません（目的が違う）。ちなみに、有名な Google Public DNS では独自の "DNS-over-HTTPS" というサービスを提供しているそうです。

- Google Public DNS over HTTPS を試す | IIJ Engineers Blog   
  http://eng-blog.iij.ad.jp/archives/85

そんなわけで、iPhone からのネットアクセスを VPN で保護したいなぁ、と思いつつ先延ばしになっていたのですが、先日、Impress INTERNET Watch で VPN サービスの紹介記事を読みました。

- 無料Wi-Fiを安全に使うための「VPNアプリ」って何？　「https」の心得も再確認 - INTERNET Watch   
  http://internet.watch.impress.co.jp/docs/special/1057386.html

記事を読んで思ったのですが、特定の企業（しかも通信事業者じゃない）にすべての通信を預けてしまうのは、ちょっとイヤ。使用している通信プロトコルの詳細は非公開だろうし、アプリやサーバの実装の安全性も不透明です。しかも有料。

今まで VPN についてちゃんと調べたことはなかったのですが、一般論として、「固定のグローバル IP アドレスを持つ Linux サーバ」があれば、おそらく VPN サーバをたてられるんじゃないかと思っていました。そして、タイミングのいいことに、実験用にレンタルしている VPS が余っていました（しばらく使っていなかったので解約しようかと思ってた）。

諸事情により時間的な余裕もあったので、VPN の構築にトライ！

## VPN とは？

- Virtual Private Network - Wikipedia   
  https://ja.wikipedia.org/wiki/Virtual_Private_Network

**注：この連載記事で言う「VPN」は、正しくは「インターネット Layer 2 VPN」のことです。**

VPN (Virtual Private Network) は、既存の TCP/IP ネットワークの上にセキュアな Layer 2 通信路を構築する技術です。「既存の TCP/IP ネットワーク」というのは、たいてい、インターネットのことを指しますが、大きな組織の内部ネットワークで特定の部門間を繋ぐ場合も話は同じです。「Layer 2 通信路」というのは OSI 参照モデルの第2層（データリンク層）のことで、ふつうに言えばイーサネット (Ethernet) のことです。つまり、VPN は、異なる Ethernet ネットワークに存在している機器の間で、インターネットを経由した Ethernet 通信ができるようにする技術です。

通常、Ethernet のパケット（正確には「フレーム」）はルータを越えられません。ひとつの Ethernet スイッチ／ハブに接続している機器どうし、あるいはカスケード接続された複数の Ethernet スイッチ／ハブのいずれかに接続している機器の間で、直接 Ethernet フレームを送受信します。この「直接 Ethernet フレームをやりとりできるネットワーク」のことを Ethernet 用語では「セグメント」と呼びます。TCP/IP で「サブネット」と言ったときは、多くの場合、この「セグメント」のことを指しています（階層的な大規模ネットワークでは違います）。また、「LAN」(Local Area Network) という言葉もほぼ同義語です（定義は曖昧ですが）。

Ethernet ブリッジというものがあります。ふたつのセグメントをブリッジで接続すると、単一のセグメントとして使うことができます。スイッチ／ハブをカスケード接続したのと同じようなネットワーク構成になります。スイッチ／ハブとの違いと言えば、ブリッジは通常2個のポートしか持たず、ふたつのセグメントを接続する役目に特化している、という点くらいでしょうか。実際のところ、物理的にネットワークを構築するときにブリッジを使うことはほとんと無いでしょう。しかし、VPN を構築するときには「ブリッジ」という用語がよく出てきます。

VPN を使うと、複数の物理的なセグメントを、単一のセグメントにすることができます（仮想ブリッジ機能）。また、セグメントの外に存在する機器を、そのセグメントに接続されているように機能させることもできます（リモートアクセス機能）。

VPN を使うための第一条件は、VPN で接続させたい機器どうしで直接、あるいは仲介する VPN サーバとそれぞれの機器の間で、TCP/IP 通信が可能なことです。後者の場合、複数の VPN サーバを連携させることも可能なので、同じ VPN サーバへの TCP/IP 通信が必須というわけではありません。また、別の条件として、VPN で接続させたい機器の片方、あるいは仲介する VPN サーバが、固定のグローバル IP アドレスを持っていることが望ましいです。しかし、この条件は回避する手段があるので、必須条件ではありません。これらの条件は使用する VPN 方式によって異なります。

## VPN にもいろいろある

ひと言で「VPN」と言っても、様々な方式があります。また、それぞれの方式には、複数の実装（その方式を実現するためのハードウェアやソフトウェア）があります。ひとつの実装で複数の方式に対応しているものもあります。方式や実装の違いにより、実現可能なネットワーク構成や、VPN 接続する機器に対する条件、通信の安全性・安定性・速度などが異なります。

メジャーな VPN の方式には以下のようなものがあるみたいです：

- PPTP
- L2TP/IPsec (L2TPv3 over IPsec)
- EtherIP over IPsec
- OpenVPN
- IKEv2
- MS-SSTP
- SoftEther VPN

これらの比較記事もあります：

- PPTP vs L2TP/IPSec vs OpenVPN vs IKEv2 - Tech Beans   
  http://soymsk.hatenablog.com/entry/2016/10/05/234551
- yamata::memo: OpenVPNをお勧めできる6つの理由   
  http://yamatamemo.blogspot.jp/2013/04/openvpn6.html
- SoftEther VPN の概要・特徴 - SoftEther VPN プロジェクト   
  https://ja.softether.org/1-features

VPN の実装もいろいろあります：

- ハードウェアによる実装
  - Cisco などの企業向けルータ
  - NEC などのホームルータ
- ソフトウェアによる実装
  - OpenVPN
  - strongSwan
  - SoftEther VPN
  - OS 組み込みのクライアント機能（Windows / macOS / iOS / Android 等）

この連載記事では、サーバとして SoftEther VPN Server の Linux 版を、クライアント機器として iPhone と Windows PC を使います。

## VPN でやりたいこと

今回、VPN を構築して実現したいことは、次の3点です：

1. iPhone からのネットアクセスを VPN サーバ経由にして暗号化。   
   https://ja.softether.org/4-docs/2-howto/5.VPN_for_Home/2.Comfortable_Network_Anywhere   
   ただし、VPN サーバは自宅ではなくクラウド (VPS) に設置。
1. iPhone から自宅の Windows PC にリモートアクセス。   
   https://ja.softether.org/4-docs/2-howto/1.VPN_for_On-premise/1.Ad-hoc_VPN
1. iPhone から自宅 LAN にリモートアクセス。   
   https://ja.softether.org/4-docs/2-howto/5.VPN_for_Home/1.Remote_Access

3番目の意図は、自宅 LAN 上にある（VPN クライアント機能のない）機器にもリモートアクセスしたい、というものです。たとえば NAS とか。
