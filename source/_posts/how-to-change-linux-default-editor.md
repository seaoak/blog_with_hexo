---
title: Linux でシステムデフォルトのエディタを変えたい
date: 2017-06-14 09:39:14
updated: 2017-06-14 09:39:14
tags:
---

Ubuntu 16.04 のシステムデフォルトのエディタは nano です。Seaoak は nano の使い方がわからないので、vi を使いたい。しかし、毎回 `EDITOR=vi` を付けて sudo するのが面倒です。

以下のコマンドを実行すると、インタラクティブに変更できます：

```
$ sudo update-update-alternatives --config editor
```

ちなみに、Ubuntu 16.04 には素の vi は入っておらず、実体は `/usr/bin/vim.tiny` でした。
