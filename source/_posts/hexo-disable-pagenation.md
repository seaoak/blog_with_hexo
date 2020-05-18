---
title: pagenation を無効化したい
date: 2017-02-14 12:45:06
updated: 2017-02-14 12:45:06
tags:
  - Hexo
---
Hexo の過去記事ページ (archives) やタグごとのページで
pagenation （複数ページへの分割）をやめたい。

デフォルトでこの機能はあって、`_config.yml` で設定可能です。


## アーカイブページの pagenation を無効化する

https://github.com/hexojs/hexo-generator-archive

```yaml
archive_generator:
  per_page: 0
  yearly: true
  monthly: true
  daily: false
```

## Tags ページの pagenation を無効化する

https://github.com/hexojs/hexo-generator-tag

```yaml
tag_generator:
  per_page: 0
```
