---
title: Linux でのアカウント操作メモ
date: 2017-06-13 09:24:03
updated: 2017-06-13 09:24:03
tags:
---


## 普通のユーザ foo の新規作成

```
$ sudo adduser foo
```

ユーザ名と同じ名前のグループ foo が自動的に作成されます。


## 名前だけのユーザ foo を新規作成

nobody みたいなユーザを作れます。ログイン不可＆ホームディレクトリ無しです。

```
$ sudo adduser --home /noexistent --shell /bin/false --no-create-home --disabled-password --disabled-login foo
```

ユーザ名と同じ名前のグループ foo が自動的に作成されます。


## パスワードを無効化（su と sudo のみ可能に）

普通に作ったユーザのパスワードを後から無効化できます。

```
$ sudo usermod --expiredate 1 --lock foo
```

`--expiredate` オプションによりアカウントへのログインができなくなります。公開鍵証明書認証による ssh リモートログインもできなくなります。また、cron も実行できなくなるのでご注意。

`--lock` オプションにより `/etc/shadow` のパスワードフィールドの先頭にエクスクラメーションマーク (`!`) が付与されます。これが「パスワード無効」を意味しています。


## 既存ユーザのログインシェルを無効化（su も不可に）

```
$ sudo usermod --shell /bin/false foo
```

ただし、`sudo -u USERNAME -i` でインタラクティブなシェルが使えてしまうので注意。


## 既存ユーザのログインを再び有効化

```
$ sudo usermod --expiredate '' --shell /bin/bash foo
```

パスワードのロック状態については変更されません。公開鍵証明書認証による ssh リモートログインや `su` は可能になります。


## 名前だけのグループを新規作成

```
$ sudo addgroup foo
```


## 既存ユーザ foo を既存グループ bar に参加させる

```
$ sudo adduser foo bar
```

ちなみに、`usermod -G` はダメらしいです。すでに参加しているグループから抜けてしまいます。`usermod -a -G` なら OK です。

- usermod -G でユーザに新しいサブグループを追加してはいけない - 続・夕陽のプログラマ   
  http://d.hatena.ne.jp/thegoodbadugly/touch/20130116/1358316032
