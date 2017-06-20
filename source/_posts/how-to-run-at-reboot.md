---
title: システム起動時にプログラムを自動実行させたい
date: 2017-06-20 20:53:39
tags:
 - SoftEtherVPN
---

昨日、iPhone から VPN 接続ができなくなってしまいました。調べてみると、SoftEther VPN Server を動かしている VPS が勝手に再起動してました。原因は不明。

先日記事にしたように、SoftEther VPN Server は一般ユーザ権限で「ユーザモード」で動かしています。当然ながら `/etc/rc` スクリプトなど置いてないので、サーバがリブートしてしまうと SoftEther VPN Server は落ちたままです。

不便なのでちょっと調べてみたところ、cron に「システム起動時に自動的にプログラムを実行する」という機能があることを知りました。

- システム起動時に特定のコマンドを実行するには － ＠IT   
  http://www.atmarkit.co.jp/flinux/rensai/linuxtips/a029crontabstartup.html

この機能を使えば、一般ユーザでもシステム起動時に自動的に SoftEther VPN Server を実行できます。

cron にこんな機能があるのは知りませんでした。便利ですね！
