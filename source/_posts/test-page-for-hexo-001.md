---
title: テストページ for Hexo その１
date: 1999-01-01 00:00:00
updated: 2017-01-13
tags:
 - Test
---
※このページは Hexo の動作確認のためのものです。内容は無視してください。

---
### なぜ alias 設定が有効になってしまうのか

`/usr/bin/bash --login -i` というオプション付きで bash にシェルスクリプトが渡されるから。

`man bash(1)` によれば、

{% blockquote %}
_aaa_
bbb

```
This is a test.
```

ccc
{% endblockquote %}

```
   A login shell is one whose first character of argument zero is a -,  or
   one started with the --login option.

   An  interactive  shell  is one started without non-option arguments and
   without the -c option whose standard input and error are both connected
   to  terminals  (as determined by isatty(3)), or one started with the -i
   option.  PS1 is set and $- includes i if bash is interactive,  allowing
   a shell script or a startup file to test this state.
```
ddd
```javascript
(function(e) {
  var i = e + 'hogehoge';
  return i;
})();
```
とのことなので、bash は "interactive login shell" として起動されたことになります。
そして、さらに man を読むと、
{% blockquote https://arg.plugin.hexo.example.com/ %}
```
   When bash is invoked as an interactive login shell, or as a  non-inter‐
   active  shell with the --login option, it first reads and executes com‐
   mands from the file /etc/profile, if that file exists.   After  reading
   that file, it looks for ~/.bash_profile, ~/.bash_login, and ~/.profile,
   in that order, and reads and executes commands from the first one  that
   exists  and  is  readable.  The --noprofile option may be used when the
   shell is started to inhibit this behavior.
```
{% endblockquote %}


{% blockquote %}
```
This is a test.
```
{% endblockquote %}

とのことなので、bash は `/etc/profile` を読み込みます。
`/etc/profile` の中では `/etc/profile.d/*.sh` を順次読み込みます。
`/etc/profile.d/aliases.sh` を読み込むと、次のように ls コマンドの alias が設定されます：
```
alias ls='ls -F --color=auto --show-control-chars'
```
また、`~/.bash_profile` 経由で `~/.bashrc` も読み込まれるので、
個人的に ls コマンドの alias 設定をしていれば上書きされます。
