---
title: Hexo で画像リンクを作りたい
date: 2016-11-07 18:53:52
updated: 2016-11-07
tags:
 - Hexo
---

静的サイトジェネレータ [Hexo](https://hexo.io/) はじめました。

実は Markdown を書くのは初めてだったりするので、
試行錯誤の連続です。
まぁ、Wiki には慣れているのでそれほど違和感はない。

とりあえず、手元の Ubuntu サーバで Hexo server が動くところまで来ました。

しかし、ここで、ちょっとした問題が発生。
原因と回避策は判明したのですが、
調べた限りだと日本語の記事は見つからなかったので、
記事にしておきます。

今回の環境は以下の通り：
```
hexo: 3.2.2
hexo-cli: 1.0.2
node: 6.9.1
```

なお、長文になってしまったので先に結論を言っておくと、
こちらの英語記事がとりあえずの正解でした：  
http://alexdrenea.com/2016/04/28/hexo-image-hacking/


## やりたいこと

Hexo の投稿記事の中で画像リンクを張ろうとしました。
具体的に言うと、本の表紙画像をクリックすると Amazon に飛ぶようにしたかった。

HTML で書くとこんな感じ：
```html
<a herf="https://www.amazon.co.jp/dp/4048669095/">
  <img src="/2016/11/06/book-uminosoko/book01.jpg" />
</a>
```


## まずは画像の貼り方

まず参考にしたのは Qiita のこの記事：
> [Hexoで始めるお手軽な静的ブログ　-画像投稿とプラグインの追加-](http://qiita.com/in_silico_/items/31c2c0bc1cf061c86250)

おかげで Asset の使い方が理解できました。
`asset_img` タグも使えたし、`img` タグを直接書くのも OK.
`post_path` タグだけじゃなくて `asset_path` タグでも問題ありませんでした
（記事名を書かなくて済むので後者のほうが楽）。

これでとりあえず画像は貼れるようになりました。


## Fancybox が邪魔

次に画像にリンクを張ろうと思ったのですが、
その前の時点ですでに自動でリンクが張られていました。
いわゆる Lightbox 的な機能で、
画像をクリックすると原寸画像がオーバーレイ表示される仕掛けです。

`asset_img` タグを使った場合だけじゃなくて、
`img` タグを直接書いても自動加工されてしまいます。

ブラウザの開発ツール (Google Chrome Developer Tools) で見ると、
`class="fancybox"` が付いた `a` 要素が自動生成されていました。
（あとキャプションも）

```html
<a href="/2016/11/06/book-uminosoko/book01.jpg" title="有川浩「海の底」" class="fancybox" rel="article1">
  <img src="/2016/11/06/book-uminosoko/book01.jpg" alt="有川浩「海の底」" title="有川浩「海の底」">
</a>
<span class="caption">有川浩「海の底」</span>
```

ためしに Markdown 上で画像を `a` タグで囲ってみましたが、
上記の内側の `a` 要素が優先されてしまってダメでした。

```html
<a href="https://www.amazon.co.jp/dp/4048669095/" target="_blank">
{% asset_img book01.jpg "有川浩「海の底」" %}
</a>

```
↓
```html
<a href="https://www.amazon.co.jp/dp/4048669095/" target="_blank">
  <a href="/2016/11/06/book-uminosoko/book01.jpg" title="有川浩「海の底」" class="fancybox" rel="article1">
    <img src="/2016/11/06/book-uminosoko/book01.jpg" alt="有川浩「海の底」" title="有川浩「海の底」">
  </a>
  <span class="caption">有川浩「海の底」</span>
</a>
```


## Fancybox を無効化できないか？

ちょっとググってみると、`_config.yml` または記事ソース先頭 (front-matter) で
```
fancybox: false
```
とすればよい、という[アドバイスらしきもの](https://libraries.io/github/netcan/hexo-theme-yelee)を発見（漢字読めないけど）。

たしかにソースコード (`themes/landscape/layout/_partial/after-footer.ejs`)
を見る限り、`themes/landscape/_config.yml` で `fancybox: true` しているのを
`fancybox: false` にすれば Fancybox 関連の JavaScript/CSS は読み込まれなくなる模様。

しかし、ためしてみると、Lightbox 的な挙動はなくなったものの、
自動リンクは有効なままで、Amazon へのリンクは無効なまま。


## ちゃんとソースコードを追ってみる

そもそもリンクの自動生成をしているのは誰だ？　というわけで grep した結果、
`themes/landscape/source/js/script.js` で書き換えていることが判明。

このスクリプトはそのままデプロイされるもので、ブラウザでアクセスした際に
初めて実行されます。てっきりリンクの自動生成は generate 時に行われていると
思い込んでいたので、びっくり。

当然ながら、`_config.yml` の記述なんて参照できないので、
`fancybox: false` 指定に関係なく無条件で HTML DOM を書き換えています。
ちょっとひどい。

```javascript
  // Caption
  $('.article-entry').each(function(i){
    $(this).find('img').each(function(){
      if ($(this).parent().hasClass('fancybox')) return;

      var alt = this.alt;

      if (alt) $(this).after('<span class="caption">' + alt + '</span>');

      $(this).wrap('<a href="' + this.src + '" title="' + alt + '" class="fancybox"></a>');
    });

    $(this).find('.fancybox').each(function(){
      $(this).attr('rel', 'article' + i);
    });
  });

  if ($.fancybox){
    $('.fancybox').fancybox();
  }
```

しかし、ここで一筋の光明が。

上記のコードをみればわかりますが、`img` 要素の親要素にクラス属性 `fancybox`
が指定されていると書き換えは行われません。


## 回避策

画像の親要素である `a` 要素にクラス属性 `fancybox` を指定すれば OK.

```html
<a class="fancybox" href="https://www.amazon.co.jp/dp/4048669095/" target="_blank">
{% asset_img book01.jpg "有川浩「海の底」" %}
</a>
```


## 根本的な解決策

リンクの自動生成をやめる。

具体的には、上記の `themes/landscape/source/js/script.js` のコードを
丸ごと削除（あるいはコメントアウト）する。

まぁ、そもそも Fancybox を使わない Theme を使えばよいのですが、
ちょっとギャラリーを眺めてみた限りだと見つかりませんでした。
