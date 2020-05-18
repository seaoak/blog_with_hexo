---
title: sudo を使いこなすためのメモ
date: 2017-06-13 10:29:09
updated: 2017-06-13 10:29:09
tags:
---

細かい制御が可能なので、su じゃなくて sudo を使いましょう。


## sudo 設定のお約束

- sudo の設定ファイルは `/etc/sudoers` ですが、`/etc/sudoers.d/` 内に置いたファイルもファイル名順に読み込まれます。
- これらの設定ファイルをテキストエディタで直接編集してはいけません。文法ミスとかすると**二度と sudo が使えなくなり、詰みます**。必ず visudo コマンド経由で編集してください。編集終了時に自動的に編集結果をチェックして、文法ミスなどがあれば編集結果の反映をブロックしてくれます。
- メインの設定ファイル `/etc/sudoers` を編集したいときは、`sudo visudo --strict` を実行します。
- システムデフォルトのテキストエディタが nano とかになっている場合に vi を使いたければ、`sudo EDITOR=vi visudo --strict` とすれば OK です。
- `/etc/sudoers.d/` 内の設定ファイルを新規作成／編集するときは、`sudo visudo --strict -f /etc/sudoers.d/foobar` みたいにします。
- 基本的に `/etc/sudoers` は触らず、`/etc/sudoers.d/` に個別設定ファイルを作ることをオススメします。
- ただし、`/etc/sudoers` の中で「editor 設定の無効化」だけはしておいたほうが良いみたいです。 ⇒ [参考記事](http://www.asahi-net.or.jp/~AA4T-NNGK/sudo.html#defaultsdef)
- `/etc/sudoers` の中にある `#includedir /etc/sudoers.d` という行の行頭のシャープ記号 (`#`) は、「コメントアウト」の意味ではないので削除してはいけません。
- 設定ファイルの変更は即時反映されます。システムの再起動などは不要です。
- 設定ファイルの中では各種 Alias を使うと楽です。

なお、`/etc/sudoers` に追加しておいたほうが良いのは、次の2行：

```
Defaults    !env_editor
Defaults    editor=/usr/bin/vi
```


## 環境変数（特に PATH）を引き継ぎたい

perlbrew とか nvm とか pyenv とか便利ですよね？

まぁ、最近流行の Docker を使えば話は簡単なのかもしれませんが、古い Linux カーネルの環境だと Docker が使えなかったりするので、perlbrew などの需要は今後もあると思います。仮想化方式が OpenVZ の VPS では Linux カーネルが更新できない、という話もありますし。

Ubuntu 16.04 LTS のデフォルト設定では、sudo 時に環境変数 PATH がリセットされてしまいます。したがって、ファイル先頭に `#!/usr/bin/env perl` などと書かれた Perl スクリプトを sudo で起動すると、perlbrew は無視されてしまい、システムデフォルトの perl（`/usr/bin/perl` とか）が使われます。この挙動は `/etc/sudoers` の中の `Defaults` ディレクティブで `reset_env` と `secure_path` が指定されているためです。sudo コマンドには `-E` オプションがありますが、これらの `Defaults` 設定が有効な限り、環境変数 PATH には効きません。

特権ユーザ root に sudo する場合、環境変数のリセットはセキュリティ的に妥当です。しかし、ある目的のために「特定のプログラムを特定の一般ユーザの権限で」sudo したいだけなら、環境変数を引き継ぐことも許容できると思います。sudo の設定を変える（ルールを追加する）ことで、これを実現できます。

たとえば、「ユーザ foo-runner の権限でプログラム `/home/foo-builder/bin/foo` を実行する」ことをユーザ bar に許可する場合、以下のような内容のファイルを `/etc/sudoers.d/` 内に置きます：

```
Runas_Alias FOO_RUNNERS = %foo-runner, !foo
Cmnd_Alias FOO_COMMANDS = /bin/kill, /usr/bin/test, /home/foo-builder/deploy/*/bin/foo

Defaults>FOO_RUNNERS    !env_reset
Defaults>FOO_RUNNERS    !secure_path
Defaults>FOO_RUNNERS    !authenticate

foo ALL = (FOO_RUNNERS) FOO_COMMANDS
```

`Defaults` ディレクティブを使ってシステムデフォルトの設定を限定的に上書きしているのがポイントです。あと、`/bin/kill` の実行を許可しておかないと、起動したプロセスを制御できなくなってしまうので、ご注意ください。test コマンドについても許可しておくのがオススメです（後述）。

ファイル名はわかりやすく `/etc/sudoers.d/foo` とかにしておきましょう。前述のとおり、このファイルを作成／編集するときは、必ず visudo コマンドを使いましょう（具体的には `sudo visudo --strict -f /etc/sudoers.d/foo` と実行しましょう）。ファイルのパーミッション等は visudo が適切に設定してくれます。


## sudo 実行用シェルスクリプトの例

関連ディレクトリ／ファイルへのアクセス権を確認してから起動するのがオススメです。上述の設定ファイル例で test コマンドの実行を許可しておいたのは、このため。

```bash
#!/bin/sh

set -e
set -x

RUNNER=foo-runner
FOO_ROOT=/home/foo-builder/deploy/stable

CMD=$FOO_ROOT/bin/foo
CONF=./conf/foo.conf
LOGS_DIR=./logs
PID_FILE=$LOGS_DIR/pid
DATA_DIR=./data
PREDICT="/usr/bin/nice -10"

if [ -z "$RUNNER" ]; then
    RUNNER=$USER
fi
if [ "$RUNNER" != "$USER" ]; then
    PREDICT="$PREDICT sudo -u $RUNNER"
fi

if expr "x$0" : '^x/' >/dev/null; then
    cd "`dirname \"$0\"`"
else
    cd "`dirname \"./$0\"`"
fi

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
        test "x$ARG3" = "xperl" -a "x$ARG4" = "x-x" -a "x$ARG5" = "x$FOO_ROOT/share/foo/start_server" || {
            echo "WARNING: unexpected executable name of existent process (PID:$PID) : $ARG3 $ARG4 $ARG5" 1>&2
        }
        echo $PID
    done
    return 0
}

PID=`get_existent_pid` || exit $?

start_process() {
    if [ ! -z "$PID" ]; then
        echo "ERROR: foo is already running" 1>&2
        exit 2
    fi
    for DIR in $DATA_DIR $LOGS_DIR; do
        chgrp -R $RUNNER $DIR 2>/dev/null || true
        chmod -R g+w $DIR 2>/dev/null || true
        $PREDICT test -d $DIR
        $PREDICT test -r $DIR
        $PREDICT test -x $DIR
        $PREDICT test -w $DIR
    done
    $PREDICT test -r $CONF
    $PREDICT test -f $CMD
    $PREDICT test -r $CMD
    $PREDICT test -x $CMD
    export FOO_ROOT
    umask 007
    $PREDICT $CMD -c $CONF -t
    $PREDICT $CMD -c $CONF -m daemon
}

send_signal() {
    local SIGNAL
    SIGNAL="$1"
    test "x$SIGNAL" = 'x-TERM' -o "x$SIGNAL" = 'x-HUP'
    if [ -z "$PID" ]; then
        echo "ERROR: foo is not running" 1>&2
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
        echo "Usage: $0 (start|stop|reload|restart)" 1>&2
        exit 1
        ;;
esac
```


## 参考記事

- 止められないUNIXサーバのセキュリティ対策（5）：サービスをセキュアにするための利用制限（3）～管理者権限の制限のためのsuとsudoの基本～ - ＠IT   
  http://www.atmarkit.co.jp/ait/spv/0311/05/news001.html
- Linux - sudo でパスワード要求しない！ - mk-mode BLOG   
  http://www.mk-mode.com/octopress/2014/04/17/linux-sudo-no-password/
- 特定のコマンドをパスワードなしでsudo する設定 - Slow Dance   
  http://d.hatena.ne.jp/LukeSilvia/touch/20080716/p1
- Stray Penguin - Linux Memo (Sudo)   
  http://www.asahi-net.or.jp/~AA4T-NNGK/sudo.html
