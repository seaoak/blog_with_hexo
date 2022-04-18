---
title: Firefox で新しいプロファイルをセットアップ
date: 2022-04-18 08:49:31
tags:
---
メインの Web ブラウザとして、[Mozilla Firefox](https://www.mozilla.org/ja/firefox/new/) を使わせていただいています。

- 用途ごとにプロファイルを使い分けられる（ブックマークやアドオンや開いたままのタブの状態を別個に管理できる）
- タブバーの縦置きができる
- 勝手に Google に情報が送信されることがないのでプライバシー的に安心
- Web の多様性のためにも応援したい

今では、8個のプロファイルを使い分けている状況です。

今回、ひさしぶりに新しいプロファイルを追加して初期設定をしたのですが、
いろいろ忘れてることがあったので、メモ代わりに記事にしておくことにしました。

## プロファイルの新規作成

プロファイルを新規に作成するには、Firefox の「プロファイルについて」画面を開きます。
具体的には、Firefox のアドレスバーに `about:profiles` と入力します。

{% asset_img SS20220418b_Firefox_profiles.jpg "Firefox の about:profiles 画面" %}

この画面で、「新しいプロファイルを作成」ボタンを押します。
「プロファイル作成ウィザード」が開くので、「次へ」ボタンを押します。
すると、新しいプロファイルの名前を聞かれるので、入力します。
この名前はそのままプロファイルデータを格納するフォルダの名前として使われるので、
「英数字のみ」で指定することをオススメします。
漢字ひらがなとか、スペースとかは、たぶん避けたほうが安全。

「完了」ボタンを押すと、「プロファイルについて」画面に戻ります。
新しく作ったプロファイルの情報が一覧に追加されているハズです。

この状態では、新しく作ったプロファイルが「既定のプロファイル」になってしまっているので、
元のデフォルトのプロファイルのところにある「既定のプロファイルに設定」ボタンを押しておきます。
これを忘れると、オプション無しで Firefox を起動したときのプロファイルが変わってしまいます。

## 新しいプロファイルを指定して Firefox を起動するショートカットを作っておく

プロファイルを指定して Firefox を起動するためには、`firefox.exe` にオプションを指定する必要があります。
具体的には、`-no-remote -P "プロファイル名"` を付けます。

スタートメニューに登録されている Firefox のショートカットをコピーして、
そのプロパティを開いて、「リンク先」欄に文字列を追加します。

{% asset_img SS20220418c_Firefox_shortcut.jpg "ショートカットにオプションを指定する例" %}

## タブバーを縦置きにする

タブバーを右サイドバーとして設定することで、縦置きにします。
アドオンを入れて、アドオンのスタイルシートで見た目を調整して、さらに Firefox 自体のスタイルシートもカスタマイズします。

こんなイメージになります：

{% asset_img SS20220418a_Firefox_sample.jpg "カスタマイズ後の Firefox のイメージ" %}

{% post_link firefox-addon-vertical-tabs "2016年に書いた記事" %}では Vertical Tabs Reloaded というアドオンをご紹介しましたが、
今は別のアドオンを使わせていただいています。

### アドオンをインストール

アドオンというのは、今の Firefox では主に「拡張機能」と呼ばれていますが、まぁ、同じ意味です。

タブバーを縦置きにするために、「Tree Style Tab - ツリー型タブ」というアドオンをインストールします。

https://addons.mozilla.org/ja/firefox/addon/tree-style-tab/

Firefox の「拡張機能」画面の右上にある「アドオンを探す」欄で「Tree Style Tab」と入力すれば、
上記の URL に飛べるはずです。このページにある「Firefox へ追加」ボタンを押せばインストールできます。

いくつかアクセス権についてダイアログが出ると思いますが、「許可」しておきます。

左サイドバーとして「ツリー型タブ」が開くので、右に移動します。
具体的には、左サイドバーの上部の「ツリー型タブ &#8744;」となっているところをクリックして、
開いたメニューから「サイドバーを右側へ移動」を選択します。

{% asset_img SS20220418e_Firefox_TST_move.jpg "サイドバーを右に移動" %}

あと、設定を進めていくと、ツリー型タブからの確認メッセージが出るかと思います。

{% asset_img SS20220418f_Firefox_TST_prompt.jpg "表示切り替えのダイアログ" %}

ここは、素直に「右側用の設定に切り替える」を選択すれば OK です。

### アドオンのオプション設定

Firefox の「拡張機能」画面から「Tree Style Tab - ツリー型タブ」のオプション設定画面を開きます。

すごくたくさんの項目があって戸惑うかもしれませんが、初期設定のままでも使えると思います。
今回は、「タブをグループにまとめる機能は使わない」「タブバーには詰め積めで表示させる」ようにしてみます。

まず、「外観」のところで、「装飾無し」を選択しておきます。

{% asset_img SS20220418d_Firefox_TST_options1.jpg "Tree Style Tab のオプション設定（外観）" %}

次に、「詳細設定」のところにある「ツリー型タブが提供するページ用の追加のスタイル指定」欄で、スタイルシート (CSS) の記述を追加します。

{% asset_img SS20220418g_Firefox_TST_options2.jpg "スタイル指定の欄" %}

ここのテキスト入力欄にはすでに CSS の記述が書かれています（実際にはコメントアウトされているので無効になっています）。
その内容に追加する形で、以下のテキストをコピペします。

```css
/* Active tab */
.tab.active {
    background-color: #fcc;
}

/* Hovered tab */
.tab:hover {
    background: #ffc !important;
    opacity: 1;
}

/* Hide the "new tab" button at the bottom edge of the tab bar */
.newtab-button-box {
    display: none;
}

/* Adjust color with the theme */
#tabbar {
    background-color: var(--theme-colors-toolbar);
}
```

上記のテキスト (CSS) は、4個の設定をしています。

- アクティブなタブがひと目でわかるように色を変える（薄い赤）
- タブバーの上にマウスカーソルがあるときに、マウスカーソルの下のタブの色を変える（薄い黄色）
- タブバーの下端に表示される「新しいタブを追加」ボタンを削除
- タブバー全体の色を Firefox のテーマに合わせる

なお、4番目の設定は、Firefox のテーマによってはうまく機能しないので、
その場合は以下のように明示的に RGB 色指定をするように書き替えてみてください。

```css
/* Adjust color with the theme */
#tabbar {
    background-color: #ffe0f0;
}
```

### 水平タブバーとサイドバータイトルを消す

右サイドバーとしてタブを縦置きできたわけですが、もともとウインドウ上部に存在している水平タブバーが邪魔ですよね。
あと、右サイドバーの上端に「ツリー型タブ」とタイトルが表示されているのも表示領域の無駄遣いです。

これらを消すには、Firefox のマイナーな機能である userChrome.css を使います。
"Chrome" と名前が付いていますが、Google Chrome ブラウザとは関係ありません。
「見た目の装飾」くらいの意味で使われる俗語で、Firefox においてはツールバーやタブバーなどの UI パーツを意味します。

userChrome.css というのは、Firefox のプロファイルのフォルダ内に `chrome` という名前のフォルダを作って、
その中に `userChrome.css` というテキストファイル（CSS ファイル）を置くと、Firefox の見た目をカスタマイズできる、という機能です。
**なお、この機能は deprecated らしいので、そのうち使えなくなるかもしれません。**

- UserChrome.css - MozillaZine Knowledge Base   
  https://kb.mozillazine.org/index.php?title=UserChrome.css
- Code snippets for custom style rules ・ piroor/treestyletab Wiki ・ GitHub   
  https://github.com/piroor/treestyletab/wiki/Code-snippets-for-custom-style-rules#for-userchromecss
- Firefox userChrome.css ・ GitHub   
  https://gist.github.com/Zren/37bed9ed257347d97233273f32287707

まず、デフォルトでは Firefox は userChrome.css を読み込んでくれません（昔はデフォルトで読み込んでくれていた模様）。
Firefox のアドレスバーに `about:config` と入力して「高度な設定」画面を開きます。
「注意して進んでください！」という警告が出ますが、「危険性を承知の上で使用する」ボタンを押して先に進めます。
ページ上部の「設定名を検索」欄に `toolkit.legacyUserProfileCustomizations.stylesheets` と入力します。
すると、プロパティが1行表示されて、値が `false` になっているハズです。
この行をマウスでダブルクリックすると、値が `true` に変わります。
これで userChrome.css を読み込んでくれるようになったので、「高度な設定」ページを閉じます。

次に、userChrome.css というファイルを作ります。

エクスプローラでプロファイルのフォルダを開きます。
フォルダがどこにあるかわからない場合は、Firefox のアドレスバーに `about:profiles` と入力して、
新しく作ったプロファイルのところの表の中の「ルートディレクトリー」の行の「フォルダーを開く」ボタンを押せば OK です。

Firefox はいったん終了させておきます。

エクスプローラでプロファイルのフォルダを開いたら、`chrome` フォルダを掘ります。もともと存在していたらそのままで OK です。

`chrome` フォルダに移動して、`userChrome.css` というテキストファイルを新規作成します（もともと無ければ）。
とりあえず拡張子 `.txt` で作成して、中身を書いてからエクスプローラ上で拡張子を `.css` に変更してもかまいません。
メモ帳とかを使って、そのテキストファイルに以下の内容を書きます。

```css
@namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");

/* Hide horizontal tabs at the top of the window */
#TabsToolbar {
  visibility: collapse !important;
}

/* Hide the header at the top of the ANY sidebar */
#sidebar-header {
  display: none;
}
```

上記の `@namespace ...` の行は、必ずファイルの先頭に書かなければなりません。
もともとファイルが存在していて、同じ記述があったら追加不要です。

また、もともとファイルが存在していた場合、残りの行はファイル末尾に追記する形で OK です。

最後に、ファイルの拡張子が `.css` になっているのを再確認して、Firefox を起動します。

無事に水平タブバーが消えていれば、OK です。

## マウスホイールでタブを切り替えたい

右サイドバーのタブバーの上でマウスホイールを回転させてタブを切り替えられると、便利です。

アドオン「TST Mouse Wheel and Double Click」をインストールします。

https://addons.mozilla.org/ja/firefox/addon/tree-style-tab-mouse-wheel/

インストールしたら、「拡張機能」の「オプション」画面を開きます。
基本的には、チェックボックスは全部 OFF にすれば OK だと思いますが、お好みで。
変更したら、最後に左下の「Save Options」ボタンを押すのを忘れずに。

## ページタイトルと URL をクリップボードにコピー

メモに残したり Twitter に投稿したりするとき、開いているページのタイトルと URL を手軽にコピペできると便利です。

Format Link というアドオンを使わせていただいています。

https://addons.mozilla.org/ja/firefox/addon/format-link3/

たとえば、Markdown の List Item としてメモしておきたい場合、

```
- {{text}}   \n  {{url}}\n
```

とか指定しておくと便利です。

## おまけ

`about:config` で開く「高度な設定」画面から、便利な設定ができます。

- ブックマークをクリックしたときに新しいタブで開くようにするには、`browser.tabs.loadBookmarksInTabs` を `true` にすればよい。
- 検索バーでの検索結果を新しいタブで開くようにするには、`browser.search.openintab` を `true` にすればよい。
- URL の国際化表記を強制停止する（強制的に Punycode 表記にする）には、`network.IDN_show_punycode` を `true` にすればよい。フィッシング対策のひとつ。
