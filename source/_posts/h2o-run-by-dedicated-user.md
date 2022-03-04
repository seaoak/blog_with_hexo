---
title: H2O を専用のユーザで運用したい
date: 2017-06-14 10:23:23
updated: 2017-06-14 10:23:23
tags:
 - H2O
---

Web サーバ H2O を「よりセキュアに」運用したいと思って、ちょっと試してみたお話です。H2O 専用のユーザを4個作って役割分担します。

- H2O - the optimized HTTP/2 server   
  https://h2o.examp1e.net


## まえがき

今回のお話の目標：

- 万一、H2O プロセスが乗っ取られても、被害を最小限に抑えたい。
- 関連ディレクトリ／ファイルへのアクセス権は必要最小限にしたい。
- 使用する H2O のバージョンを簡単に切り替えられるようにしたい。

この目標を実現するための設定のポイント：

- H2O プロセスのユーザはログイン不可かつホームディレクトリなし。
- H2O プロセスは H2O 管理専用ユーザが sudo で起動する。
- H2O 実行ファイル一式をビルドして保持する専用ユーザを用意する。
- H2O で配信するコンテンツデータを保持する専用ユーザを用意する。

{% asset_img figure01b.png %}

なお、「H2O プロセス専用のユーザで H2O プロセスを起動する」のは、sudo を使わずに H2O 実行ファイルに setuid することでも可能です。今回、sudo を使った理由は、以下のようなものです：

- 複数の H2O インスタンスを動かしたいとき（これは改めて記事を書きます）、それぞれの H2O 専用ユーザごとに H2O 実行ファイル一式を配置すると管理が煩雑になる。
- バージョンアップなどで H2O をビルドして配置するたびに root 権限で setuid するのが面倒（自動化するには結局 sudo が要る）。
- H2O プロセスにシグナルを送る（kill コマンドを使う）ためのプログラムを作るのが面倒（シェルスクリプトへの setuid は避けたい）。sudo なら sudo 設定ファイルで `/bin/kill` の実行を許可しておくだけで済む。

なお、H2O には、root 権限で起動された場合に指定されたユーザに切り替えてから動作する、という機能があります。今回、この機能を使わずに sudo を使った理由は、以下のようなものです：

- たとえ一瞬であっても H2O に root 権限を与えたくない。
- perlbrew の類いを有効にするために環境変数 PATH を H2O プロセスに引き継ぐ方法がわからない。


## 専用ユーザの作成

- 「H2O 管理専用ユーザ」をひとつ新規作成する。たとえば `h2o-manager` とか。
- 「H2O ビルド専用ユーザ」をひとつ新規作成する。たとえば `h2o-builder` とか。
- 「H2O 実行専用ユーザ」をひとつ新規作成する。たとえば `h2o-runner` とか。
- 「H2O 配信データ専用ユーザ」を新規作成する。たとえば `www01` とか。

なお、「H2O 配信データ専用ユーザ」は複数作って使い分けることも可能です。たとえば、SNI を使った VirtualHost 運用をする場合に、ホスト名（ドメイン名）ごとに専用ユーザを作るとか。今回はユーザ `www01` ひとつだけで説明しますが、各ユーザに同様の設定をすれば OK です。

{% asset_img figure02b.png %}

具体的な作業は以下のようになります：

```bash-prompt
$ sudo adduser --disabled-password h2o-builder
$ sudo adduser --disabled-password h2o-manager
$ sudo adduser --home /noexistent --shell /bin/false --no-create-home --disabled-password --disabled-login h2o-runner
$ sudo adduser --shell /bin/false --disabled-password www01
```

セキュリティ上の注意点として、これらのユーザには root 権限への sudo を許可してはいけません。具体的には、グループ `sudo` に参加させてはいけません。


## H2O 配信データ専用ユーザの設定

ホームディレクトリ配下に適当なディレクトリを作って、H2O で配信したいコンテンツデータ（ファイル／ディレクトリ）を置くだけです。たとえば、`~www01/htdocs/` とかに `index.html` とかを置きます。

よりセキュアな運用をしたいなら、ユーザ h2o-runner をグループ www01 に追加して、コンテンツディレクトリのパーミッションを 750 に制限します：

```bash-prompt
$ sudo adduser h2o-runner www01
$ sudo -u www01 chmod -R o-rwx ~www01/htdocs
```
逆に、特定のユーザだけにコンテンツの変更を許可したい場合、それらのユーザをグループ www01 に追加して、コンテンツディレクトリのパーミッションを 775 にします：

```bash-prompt
$ sudo adduser user77 www01
$ sudo adduser user88 www01
$ sudo -u www01 chmod -R g+w ~www01/htdocs
```

ただし、後者のようにユーザが直接ファイルを触れる運用は、個人的にはオススメできません。コンテンツデータを VCS（git とか）で管理して、ユーザ www01 が `~www01/htdocs` に checkout するのが良いと思います。checkout する作業をスクリプト化して、そのスクリプトだけ特定のユーザが `sudo -u www01` で実行できるようにしておけば運用は簡単です。

なお、上記の両方を組み合わせることも可能です（ユーザ h2o-runner をグループ www01 に追加して `chmod g+w` すればよい）。しかしながら、H2O プロセスにコンテンツディレクトリへの書き込み権限を与えることになるので、オススメしません。


## H2O ビルド専用ユーザの設定

ただ単に、GitHub のリポジトリを clone/pull して、ビルドして、格納するだけです。

```bash-prompt
$ sudo -u h2o-builder -i
$ cd /home/h2o-builder
$ mkdir deploy
$ mkdir build
$ cd build
$ git clone https://github.com/h2o/h2o.git
$ cd h2o
$ git tag
$ cp -a . ../20170614a.tag-v2.2.2
$ cd ../20170614a.tag-v2.2.2
$ git checkout v2.2.2
$ time nice -19 ionice -c 3 cmake -DCMAKE_INSTALL_PREFIX=/home/h2o-builder/deploy/h2o_20170614a.tag-v2.2.2 -DWITH_BUNDLED_SSL=on -DWITH_MRUBY=on .
$ time nice -19 ionice -c 3 make
$ time nice -19 ionice -c 3 make install
```

更新作業を自動化するシェルスクリプトを作って、cron で定期的に実行させておくと便利です。

あと、デフォルトで「安定版」を使えるように、`stable` という名前でシンボリックリンクを作っておくのもオススメです。このシンボリックリンクの張り替えは手動で良いと思います（一週間くらい様子を見てからとか）。

```bash-prompt
$ cd ~h2o-builder/deploy
$ rm -f stable
$ ln -s 20170614a.tag-v2.2.2 stable
```


## H2O 管理専用ユーザの設定

まず、管理専用ユーザ h2o-manager をグループ h2o-runner に追加しておきます：

```bash-prompt
$ sudo adduser h2o-manager h2o-runner
```


H2O 実行用のディレクトリを作って、グループ h2o-runner だけが読み出せるようにします：

```bash-prompt
$ sudo -u h2o-manager -i
$ cd ~h2o-manager
$ mkdir run
$ cd run
$ chgrp h2o-runner .
$ chmod 750 .
```

また、ログファイルと pid ファイルを置くディレクトリを作って、グループ h2o-runner に書き込み権限を与えます：

```bash-prompt
$ mkdir logs
$ chgrp h2o-runner logs
$ chmod 770 logs
```

次に、H2O 設定ファイル `/home/h2o-manager/run/h2o.conf` を作成します：

```yaml
error-log: "| rotatelogs -l /home/h2o-manager/run/logs/error-log.%Y%m%d 604800"
pid-file: /home/h2o-manager/run/logs/pid

listen:
  port: 80

hosts:
  "sentinel.example.com:0":
    paths:
      "/":
        file.dir: /dev/null
    access-log:  "| rotatelogs -l /home/h2o-manager/run/logs/access-log.sentinel.%Y%m%d 604800"

  "www01.example.com:80":
    paths:
      "/":
        file.dir: /home/www01/htdocs
    access-log:  "| rotatelogs -l /home/h2o-manager/run/logs/access-log.www01.%Y%m%d 604800"
```

念のため、最後にもう一度 chgrp と chmod を実行しておきます：

```bash-prompt
$ chgrp -R h2o-runner ~h2o-manager/run
$ chmod -R o-rwx ~h2o-manager/run
```


## sudo の設定

H2O 管理専用ユーザ h2o-manager が、H2O 実行専用ユーザ（グループ h2o-runner に所属しているユーザ）に sudo できるように設定します：

```bash-prompt
$ sudo visudo --strict -f /etc/sudoers.d/h2o
```

```/etc/sudoers.d/h2o
Runas_Alias H2O_RUNNERS = %h2o-runner, !h2o-manager
Cmnd_Alias H2O_COMMANDS = /bin/kill, /usr/bin/test, /home/h2o-builder/deploy/*/bin/h2o

Defaults>H2O_RUNNERS    !authenticate

h2o-manager ALL = (H2O_RUNNERS) H2O_COMMANDS
```


## H2O 起動スクリプトを作成

`~h2o-manager/run/run.sh` とかを作ります。

例：

```bash
#!/bin/sh

set -e
set -x

H2O_ROOT="${H2O_ROOT:-/home/h2o-builder/deploy/stable}"
LOGS_DIR="/home/h2o-manager/run/logs"
CONF_FILE="/home/h2o-manager/run/h2o.conf"
PID_FILE="$LOGS_DIR/pid"
CMD="$H2O_ROOT/bin/h2o"
RUNNER=h2o-runner

: '======================================================================'

SELF="$0"
expr "x$SELF" : '^x/' >/dev/null || SELF="./$SELF"

PREDICT="/usr/bin/nice -n 10"
test "$RUNNER" = "$USER" || PREDICT="$PREDICT sudo -u $RUNNER"

cd "`dirname \"$SELF\"`"

get_existent_pid() {
    test ! -z "$PID_FILE" || {
        echo "ERROR: BUG: invaild PID_FILE : $PID_FILE" 1>&2
        return 99
    }
    test -e $PID_FILE || return 0
    test -r $PID_FILE || {
        echo "ERROR: can not read $PID_FILE (permission error)" 1>&2
        return 99
    }
    local STATUS
    STATUS=
    local PID
    PID="`cat $PID_FILE`" || STATUS="$?"
    test -z "$STATUS" || {
        echo "ERROR: can not read $PID_FILE (status=$STATUS)" 1>&2
        return 99
    }
    expr "x$PID" : '^x[1-9][0-9]*$' >/dev/null || {
        echo "ERROR: detect unexpected contents in $PID_FILE : $PID" 1>&2
        return 99
    }
    ps --no-headers --quick-pid $PID -o comm,user,cmd |
    while read ARG1 ARG2 ARG3 ARG4 ARG5 ARGS; do
        COMM=perl
        test "x$ARG1" = "x$COMM" || return 0
        test "x$ARG2" = "x$RUNNER" || {
            echo "ERROR: the owner of existent process (PID:$PID) is not $RUNNER : $ARG2" 1>&2
            return 3
        }
        test "x$ARG3" = "xperl" -a "x$ARG4" = "x-x" -a "x$ARG5" = "x$H2O_ROOT/share/h2o/start_server" || {
            echo "WARNING: unexpected executable name of existent process (PID:$PID) : $ARG3 $ARG4 $ARG5" 1>&2
        }
        echo $PID
    done
    return 0
}

PID=`get_existent_pid` || exit $?

start_process() {
    if [ ! -z "$PID" ]; then
        echo "ERROR: h2o is already running" 1>&2
        exit 2
    fi

    chgrp -R $RUNNER $LOGS_DIR 2>/dev/null || true
    chmod -R g+w $LOGS_DIR 2>/dev/null || true
    $PREDICT test -d $LOGS_DIR
    $PREDICT test -r $LOGS_DIR
    $PREDICT test -x $LOGS_DIR
    $PREDICT test -w $LOGS_DIR

    $PREDICT test -r $CONF_FILE
    $PREDICT test -f $CMD
    $PREDICT test -r $CMD
    $PREDICT test -x $CMD
    export H2O_ROOT
    umask 007
    $PREDICT $CMD -c $CONF_FILE -t
    $PREDICT $CMD -c $CONF_FILE -m daemon
}

send_signal() {
    local SIGNAL
    SIGNAL="$1"
    test "x$SIGNAL" = 'x-TERM' -o "x$SIGNAL" = 'x-HUP'
    if [ -z "$PID" ]; then
        echo "ERROR: h2o is not running" 1>&2
        exit 2
    fi
    $PREDICT /bin/kill $SIGNAL $PID
}

case "$1" in
    start)
        start_process
        ;;
    stop)
        send_signal -TERM
        wait $PID || echo "WARNING: status=$?" 1>&2
        ;;
    reload)
        send_signal -HUP
        ;;
    restart)
        "./`basename \"$0\"`" stop
        "./`basename \"$0\"`" start
        ;;
    *)
        echo "Usage: `basename \"$SELF\"` (start|stop|reload|restart)" 1>&2
        exit 1
        ;;
esac
: 'Completed'
```

ポイントは、環境変数 `H2O_ROOT` を設定して export することです。これを忘れると H2O が関連ファイルを見つけられずにエラーになります。環境変数 PATH は特に変更する必要はありません。

あと、sudo コマンドには `-E` オプションは付けません。付けるとエラーになります。これは、上記の `/etc/sudoers.d/h2o` の中で `setenv` の `Defaults` ディレクティブを記述してしていないためです。そもそも、`!reset_env` の `Defaults` ディレクティブを記述しているので、`-E` オプションは不要（無意味）なのです。


## H2O の起動

H2O 管理専用ユーザ h2o-manager として、上記の起動スクリプトを実行するだけです：

```bash-prompt
$ sudo -u h2o-manager ~h2o-manager/run/run.sh start
```

正常に起動できれば、サブディレクトリ `/home/h2o-manager/run/logs/` にログファイルと pid ファイルが生成されているハズです。あと、`netstat -antu` を実行すれば、待ち受けポート（80/tcp とか 443/tcp とか）を listen しているのを確認できるハズです。


## H2O の停止

実行すると `kill -TERM` します。

```bash-prompt
$ sudo -u h2o-manager ~h2o-manager/run/run.sh stop
```


## H2O の再起動

H2O が listen するポートを変えたいときは、reload ではダメなので restart します。

```bash-prompt
$ sudo -u h2o-manager ~h2o-manager/run/run.sh restart
```


## H2O 設定ファイルのリロード

H2O 設定ファイルを更新したときには reload します。実行すると `kill -HUP` します。

```bash-prompt
$ sudo -u h2o-manager ~h2o-manager/run/run.sh reload
```
