---
title: テストページ for Hexo その２
date: 1999-01-02 00:00:00
updated: 2017-01-13
tags: 
 - Test
---
※このページは Hexo の動作確認のためのものです。内容は無視してください。

---
## レベル２の表題

This is a pen.


{% post_path import-old-entry %}

ほげ

{% post_link import-old-entry %}

foo

{% post_link import-old-entry たいとる %}

bar

{% post_link about %}

hoge

Seaoak の[自己紹介はこちら](/about/)。

piyo

------------------------------------------------------------------------------
## rSwigComment

abcd

{# 一行こめんとのてすと #}

defg

{#
複数行コメントのてすと（１）
複数行コメントのてすと（２）
複数行コメントのてすと（３）
#}

ihjl

    {#
    入れ子の複数行コメントのてすと（１）
    {#
    入れ子の複数行コメントのてすと（２）
    #}
    入れ子の複数行コメントのてすと（３）
    #}

mnop

------------------------------------------------------------------------------
## Simple (Solo)

---
**Pattern10**

{% blockquote %}
{% endblockquote %}

---
**Pattern11**

{% blockquote %}
aaaaa
{% endblockquote %}
vvvvv

---
**Pattern12**

ttttt
{% blockquote %}
aaaaa
bbbbb

ccccc
ddddd
{% endblockquote %}
sssss

---
**Pattern13**

uuuuu
{% blockquote %}


aaaaa
bbbbb

ccccc
ddddd



{% endblockquote %}

------------------------------------------------------------------------------
## Nested Mix

---
**Pattern20**

{% blockquote %}
foo
{% pullquote %}
bar
{% endpullquote %}
baz
{% endblockquote %}

---
**Pattern21**

{% blockquote %}
hoge

{% pullquote %}
piyo

huga
{% endpullquote %}

fuga
{% endblockquote %}

---
**Pattern22**

{% blockquote %}
{% pullquote %}
hoge
hoge

foo
bar
{% endpullquote %}
{% endblockquote %}

---
**Pattern23**

{% blockquote %}
{% pullquote %}
hoge
hoge

foo
bar
{% endpullquote %}
{% pullquote %}
piyo

fuga
{% endpullquote %}
{% endblockquote %}

------------------------------------------------------------------------------
## Nested Same Tag

---
**Pattern30**

{% blockquote %}
{% blockquote %}
hoge
hoge



foo
bar
{% endblockquote %}
{% endblockquote %}

---
**Pattern31**

mmmmm
{% blockquote %}
aaaaa
{% blockquote %}
bbbbb

ccccc
{% endblockquote %}
ddddd
{% endblockquote %}
nnnnn

---
**Pattern32**

mmmmm
{% blockquote %}
aaaaa
{% blockquote %}
bbbbb

ccccc
{% endblockquote %}
ddddd
{% blockquote %}
eeeee

fffff
{% endblockquote %}
ggggg
{% endblockquote %}
nnnnn

------------------------------------------------------------------------------
## codeblock Mix

---
**Pattern40**

{% blockquote %}
aaaaa

{% codeblock %}
bbbbb

ccccc
{% endcodeblock %}
ddddd
{% endblockquote %}

---
**Pattern41**

{% blockquote %}
aaaaa

{% codeblock %}
bbbbb

ccccc
{% endcodeblock %}
ddddd

{% pullquote %}
bbbbb

ccccc
{% endpullquote %}
ddddd
{% endblockquote %}

---
**Pattern42**

{% blockquote %}
aaaaa

{% codeblock %}
bbbbb

ccccc
{% endcodeblock %}
ddddd

{% pullquote %}
eeeee

fffff
{% endpullquote %}
{% codeblock %}
ggggg

hhhhh
{% endcodeblock %}
iiiii

jjjjj
{% endblockquote %}

------------------------------------------------------------------------------
