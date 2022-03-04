---
title: Markdown の改行を無視してほしい
date: 2017-02-14 10:44:32
updated: 2017-02-14 10:44:32
tags:
  - Hexo
---
Hexo （というか Markdown 一般）で文章を書いているとき、
段落の途中で改行を入れることが普通にあります。
物理的な１行が長すぎるとテキストエディタで扱いにくいし、
git の diff も見づらくなってしまいます。

Hexo の Markdown 処理系は、ひとかたまりのテキスト（空行を区切りとする一段落）を
ひとつのパラグラフ（HTML の p 要素）に変換してくれます。
このとき、元のソースファイルの改行をそのまま保存して HTML に出力します。

例）

```
今日はいい天気ですね。
明日も晴れるでしょうか？
```

↓

```
<p>今日はいい天気ですね。
明日も晴れるでしょうか？</p>
```

さて、これはこれで一見すると問題無さそうですが、
現状の Web ブラウザでは、通常、改行が半角スペースとして解釈されてしまいます。

<pre>今日はいい天気ですね。<span style="border: 1px solid Red">&nbsp;</span>明日も晴れるでしょうか？</pre>

厳密に言うと、CSS の `white-space` プロパティの値とその解釈に依存していて、
通常の設定 (`white-space: normal`) ではブラウザがコンテキストに従って
「よきに計らって」くれることになっているのですが（半角スペース１個と解釈せずに
削除してしまってもよい）、まぁ、そこは CJK 文字圏のマイナーさということで、
Firefox とか Google Chrome とかは無条件で改行文字を半角スペースに変換します。    
https://www.w3.org/TR/CSS2/text.html#white-space-prop

ちなみに CSS3 (CSS Text Module Level 3) のドラフトでは、
中国語・日本語・Yi 文字に挟まれた改行（や半角スペースなど）は
無視するように明記されています（期待！）    
https://drafts.csswg.org/css-text-3/#propdef-white-space

閑話休題。

Hexo には、この問題を解決するためのプラグインがあります。    
https://github.com/lotabout/hexo-filter-fix-cjk-spacing

導入は簡単で、単に NPM パッケージをインストールするだけです。

```bash-prompt
$ npm install hexo-filter-fix-cjk-spacing --save
```

あとは普通に `hexo server` とか `hexo generate` とか `hexo deploy` とかすれば、
自動的に日本語文字間の改行を削除してくれます。
原稿（Markdown ソースファイル）には手を加える必要がありません。

作者の [Jinzhou Zhang さん](https://github.com/lotabout) に感謝！


なお、
この記事の話は `_config.yml` で `breaks: false` を指定している前提です。
`breaks: true` の場合はそもそも「ソースファイルの改行をそのまま反映してください」
という意味になるので、
ソースファイルの改行ごとに自動的に HTML の `<br />` 要素が追加されます。
