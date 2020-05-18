---
title: xyzzy めも
date: 2017-03-04 13:49:42
updated: 2017-03-04 13:49:42
tags:
---

xyzzy は Windows 上で動く Emacs 風なテキストエディタです。

EmacsLisp の代わりに CommonLisp を使います。

<!-- toc -->


## markdown-mode

 - 改変 markdown-mode for #xyzzy (色付け & メジャーモード化)    
   https://gist.github.com/youz/1339252/

`xyzzy/site-lisp/siteinit.l` に以下の行を追加。

```
(load-library "markdown-mode")
(push '("\\.md$" . markdown-mode) *auto-mode-alist*)
```
