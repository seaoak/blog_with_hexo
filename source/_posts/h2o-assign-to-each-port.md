---
title: 待ち受けポートごとに H2O を動かす
date: 2017-06-14 11:48:21
tags:
 - H2O
---

うちのサーバでは、デバッグ用に複数のポートをこっそり開けて H2O で待ち受けているのですが、デバッグ用なのでそのポート数は増減します。また、デバッグ用に H2O で配信したいコンテンツも変化します。そのときどきで、作成中の HTML/CSS/JavaScript ファイルが置かれたディレクトリだったり、デバッグ中の CGI プログラムだったり、UNIX Socket だったりします。

**※ポートスキャンしないでくださいね！**

H2O は複数のポートで待ち受けることができます。しかし、H2O は起動時にポートを bind するらしく、設定ファイル `h2o.conf` に `listen:` ディレクティブを追加してリロードさせても（H2O プロセスに `kill -HUP` しても）、新しく追加したポートは bind してくれません。

そこで、待ち受けポートごとに専用の H2O インスタンスを動かすことにしました。

なお、この記事は、先に投稿した記事「{% post_link h2o-run-by-dedicated-user %}」の設定を前提としています。


## H2O 実行専用ユーザを作る

待ち受けポートごとに専用のユーザを作成します。ログイン不可＆ホーム無しです。とりあえず、「h2o-PORTNUMBER」という名前にしておきます：

```
$ sudo adduser --home /noexistent --shell /bin/false --no-create-home --disabled-password --disabled-login h2o-443
$ sudo adduser --home /noexistent --shell /bin/false --no-create-home --disabled-password --disabled-login h2o-80
$ sudo adduser --home /noexistent --shell /bin/false --no-create-home --disabled-password --disabled-login h2o-22222
```

これらのユーザを、グループ h2o-runner に参加させておきます：

```
$ sudo adduser h2o-443 h2o-runner
$ sudo adduser h2o-80 h2o-runner
$ sudo adduser h2o-22222 h2o-runner
```

また、H2O 管理専用ユーザ h2o-manager を各ユーザのグループに参加させておきます：

```
$ sudo adduser h2o-manager h2o-443
$ sudo adduser h2o-manager h2o-80
$ sudo adduser h2o-manager h2o-22222
```

実際に H2O でコンテンツを配信するのは HTTPS（443番ポート）だけなので、ユーザ h2o-443 をグループ www01 に参加させておきます：

```
$ sudo adduser h2o-443 www01
```


## sudo の設定

先の記事「{% post_link h2o-run-by-dedicated-user %} 」で、すでに、H2O 管理専用ユーザ h2o-manager には、グループ h2o-runner に属するユーザに sudo する権限が与えられているので、変更は不要です。


## H2O ログディレクトリの作成

H2O 実行用ディレクトリに H2O インスタンスごとのログディレクトリを作成して、グループ権限で書き込みできるようにしておきます：

```
$ sudo -u h2o-manager -i
$ cd ~h2o-manager/run
$ for PORT in 443 80 22222; do
NAME=h2o-$PORT
TARGET=./$NAME.logs
mkdir $TARGET
chgrp $NAME $TARGET
chmod 770 $TARGET
done
```


## H2O 設定ファイルの作成

H2O インスタンスごとに作成します。

コンテンツの配信は `h2o-443.conf` で行い、`h2o-80.conf` は HTTPS へのリダイレクトだけにします。`h2o-22222.conf` は今回はデバッグ用に internal redirect (reverse proxy) としています。

`h2o-manager/run/h2o-443.conf`:

```yaml
error-log: "| rotatelogs -l /home/h2o-manager/run/h2o-443.logs/error-log.%Y%m%d 604800"
pid-file: /home/h2o-manager/run/h2o-443.logs/pid

listen:
  port: 443
  ssl:
    certificate-file: /home/h2o-manager/run/cert/www01.example.com/server.crt
    key-file: /home/h2o-manager/run/cert/www01.example.com/server.key
    dh-file: /home/h2o-manager/run/cert/www01.example.com/dhparam.pem

hosts:
  "sentinel.example.com:0":
    paths:
      "/":
        file.dir: /dev/null
    access-log:  "| rotatelogs -l /home/h2o-manager/run/h2o-443.logs/access-log.sentinel.%Y%m%d 604800"

  "www01.example.com:80":
    paths:
      "/":
        file.dir: /home/www01/htdocs
    access-log:  "| rotatelogs -l /home/h2o-manager/run/h2o-443.logs/access-log.www01.%Y%m%d 604800"
```

`h2o-manager/run/h2o-80.conf`:

```yaml
error-log: "| rotatelogs -l /home/h2o-manager/run/h2o-80.logs/error-log.%Y%m%d 604800"
pid-file: /home/h2o-manager/run/h2o-80.logs/pid

listen:
  port: 80

hosts:
  "sentinel.example.com:0":
    paths:
      "/":
        file.dir: /dev/null
    access-log:  "| rotatelogs -l /home/h2o-manager/run/h2o-80.logs/access-log.sentinel.%Y%m%d 604800"

  "www01.example.com:80":
    paths:
      "/":
        redirect:
          url: "https://www01.example.com/"
          status: 301
    access-log:  "| rotatelogs -l /home/h2o-manager/run/h2o-80.logs/access-log.www01.%Y%m%d 604800"
```

`h2o-manager/run/h2o-22222.conf`:

```yaml
error-log: "| rotatelogs -l /home/h2o-manager/run/h2o-22222.logs/error-log.%Y%m%d 604800"
pid-file: /home/h2o-manager/run/h2o-22222.logs/pid

listen:
  port: 22222

hosts:
  "sentinel.example.com:0":
    paths:
      "/":
        file.dir: /dev/null
    access-log:  "| rotatelogs -l /home/h2o-manager/run/h2o-22222.logs/access-log.sentinel.%Y%m%d 604800"

  "www01.example.com:22222":
    paths:
      "/":
        proxy.reverse.url: "http://localhost:33333/"
    access-log:  "| rotatelogs -l /home/h2o-manager/run/h2o-22222.logs/access-log.www01.%Y%m%d 604800"
```

これらのファイルはグループ権限でのみ読み出せるようにしておきます：

```
$ sudo -u h2o-manager -i
$ cd ~h2o-manager/run
$ for PORT in 443 80 22222; do
NAME=h2o-$PORT
TARGET=./$NAME.conf
chgrp $NAME $TARGET
chmod 640 $TARGET
done
```


## H2O 起動スクリプトの作成

先の記事「{% post_link h2o-run-by-dedicated-user %} 」と同じ内容のものを作って、環境変数 `RUNNER` と `LOGS_DIR` と `CONF_FILE` の値だけ変えれば OK です。


## H2O の起動／停止／再起動／リロード

先の記事「{% post_link h2o-run-by-dedicated-user %}」と同様です。
