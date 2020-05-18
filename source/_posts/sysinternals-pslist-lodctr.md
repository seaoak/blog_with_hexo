---
title: Sysinternals の pslist が動かなくなった
date: 2016-11-21 18:24:45
updated: 2016-11-21 18:24:45
tags:
---

Windows Sysinternals (http://www.sysinternals.com) は
Microsoft 謹製の Windows システムツール群です。
タスクマネージャの高機能版である Process Explorer や、
余計なプログラムが勝手に起動されるのを無効化できる Autoruns など、
高機能なものからマニアックなものまで幅広いツールが揃っています。
すべて無償で利用できます。
コマンドライン上で使う CUI プログラムが多いのも特徴。

Sysinternals に含まれるツールのひとつである pslist (https://technet.microsoft.com/ja-jp/sysinternals/pslist) は、
UNIX の ps コマンドのようなもので、
コマンドライン上で実行するとプロセスの一覧が取得できたりする CUI プログラムです。

Seaoak は Firefox のプロファイルをコピーするシェルスクリプトで
pslist を使っています。
安全のため、実行中の Firefox プロセスがいないことを pslist で確認しています。
```
if /c/sysinternals/pslist -e 'firefox'; then
	echo 'ERROR: firefox is still running.' 1>&2
	exit 2
fi
```

だいぶ前から問題なく使えていたのですが、つい先日、突然動かなくなりました。
```
C:\sysinternals>pslist

PsList v1.4 - Process information lister
Copyright (C) 2000-2016 Mark Russinovich
Sysinternals - www.sysinternals.com

Processor performance object not found on HOGE-PC
Try running Exctrlst from microsoft.com to repair the performance counters.


C:\sysinternals>
```

環境は Windows 7 Professional 64bit です。

ググってみたら、Sysinternals のフォーラムに答えが投稿されていました。

http://forum.sysinternals.com/pslist-process-performance-object_topic71_post128749.html#128749

単にコマンドライン上で `LODCTR /R` を実行するだけでした。
```
C:\sysinternals>LODCTR /R

情報: パフォーマンス カウンターの設定をシステムのバックアップ ストアから正常に再
構築しました
C:\sysinternals>
```

フォーラム投稿者に感謝！
