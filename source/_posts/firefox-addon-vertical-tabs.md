---
title: Firefox の Vertical Tabs アドオンの代替
date: 2016-11-21 19:10:25
updated: 2016-11-21 19:10:25
tags:
---

Seaoak はひとつのブラウザのウインドウでタブをたくさん開くので、
ウインドウ上辺に小さなタブがたくさん並ぶことになってしまいます。
タイトル文字列は読めないし、クリックもしにくい。

Opera や Sleipnir などは、タブバーをウインドウ右辺 or 左辺に縦置きできます。
１タブ１行なので、タイトル文字列もちゃんと読めるし、とても便利。
最近のディスプレイはみんな横長なので、
ウインドウの横幅がちょっとくらい増えても全然問題ありません。
実のところ、Windows のタスクバーも縦置きしているくらいです。

Firefox でもタブバーの縦置きをするために、
Vertical Tabs というアドオンを使っていました。    
https://addons.mozilla.org/ja/firefox/addon/vertical-tabs/

しかし、このアドオンは最終更新日が2014年3月で、もうメンテされていません。
しばらく前から動作がおかしかった（Firefox を起動したら一度アドオンを無効化して
有効化しなおさないとダメだった）のですが、
最近の Firefox 本体のアップデートでついに完全にお亡くなりになってしまいました。
ウインドウのレイアウトが崩れてページ表示領域がほとんど無くなり、
操作不能になってしまったりとか。
ちなみに、こうなったときは、Alt キーをひと押ししてメニューバーを表示させて、
「ヘルプ」の「アドオンを無効にして再起動」を選択すれば復活できます。

Vertical Tabs アドオンのソースコードは GitHub で公開されています。    
https://github.com/philikon/VerticalTabs

そこで、Fork して自作するという手も考えられたのですが、
当然ながら同じようなことを考えている人がすでにいました。

Vertical Tabs Reloaded    
https://addons.mozilla.org/ja/firefox/addon/vertical-tabs-reloaded/    
https://github.com/Croydon/vertical-tabs-reloaded

インストールしてみたら、期待通り動作しました。すばらしい！

作者様に感謝！
