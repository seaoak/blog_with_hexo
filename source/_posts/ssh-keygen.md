---
title: SSH 鍵の新規作成
date: 2017-01-22 18:30:42
updated: 2017-01-22 18:30:42
tags:
---
新規に SSH 鍵を作成したので、メモ。

 - [SSH鍵の暗号化方式を強化してみた。 - しま★りん.blog @ayurina](https://blog.ayurina.net/2016/07/15/ssh%E9%8D%B5%E3%81%AE%E6%9A%97%E5%8F%B7%E5%8C%96%E6%96%B9%E5%BC%8F%E3%82%92%E5%BC%B7%E5%8C%96%E3%81%97%E3%81%A6%E3%81%BF%E3%81%9F%E3%80%82/)
 - [sshでed25519鍵を使うようにした - @znz blog](http://blog.n-z.jp/blog/2016-12-04-ssh-ed25519.html)
 - [GitHubでEd25519鍵をつかう - ひと目で尋常じゃないもふもふだと見抜いたよ](http://jnst.hateblo.jp/entry/2014/12/15/200542)
 - [GitHubユーザーのSSH鍵6万個を調べてみた - hnwの日記](http://d.hatena.ne.jp/hnw/20140705)
 - [Upgrade your SSH keys! - blog.g3rt.nl](https://blog.g3rt.nl/upgrade-your-ssh-keys.html)
 - [SSH keys - ArchWiki](https://wiki.archlinux.org/index.php/SSH_keys)
 - [米国における暗号技術をめぐる動向 (PDF) - IPA](https://www.ipa.go.jp/files/000055177.pdf)


上記最後の IPA の PDF の p.14-15 の表をみると、
米国 NIST では 2031 年以降は、3072bit 以上の RSA か、
256bit 以上の ECDSA か、どちらかしか推奨しないらしい。

2017/Jan/22 時点での GitHub のオススメは RSA 4096bit のようです。    
https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/

古いプログラムとの互換性とか考えなければ ed25519 が安心で高速で最強らしい。


## 鍵の生成

とりあえず鍵はひととおり作っておく：

```bash
$ ssh-keygen -o -a 100 -t rsa -b 4096 -C 'hoge@example.com'
$ ssh-keygen -o -a 100 -t ecdsa -b 521 -C 'hoge@example.com'
$ ssh-keygen -o -a 100 -t ed25519 -C 'hoge@example.com'
$ chmod 400 ~/.ssh/id_*
$ chmod 444 ~/.ssh/id_*.pub
$ ssh -V > ~/.ssh/memo.txt 2>&1
$ uname -a >> ~/.ssh/memo.txt
$ \grep '^VERSION=' /etc/os-release >> ~/.ssh/memo.txt
$ date >> ~/.ssh/memo.txt
$ chmod 400 ~/.ssh/memo.txt
```

ちなみに、ed25519 の場合は `-b` オプションは無視されます
（`man ssh-keygen` 参照）。
実際に生成された鍵を確認すると 256bit 固定のようです。    

秘密鍵ファイルが漏れたときの保険として、round 回数 `100` にしました。
これで、実際に秘密鍵ファイルを解読するときは1秒くらい待たされます。

あとは相手の `~/.ssh/authorized_keys` に自分の `id_ed25519.pub`
の中身（1行だけ）を追加すれば OK です。


なお、ローカルに複数の鍵ファイルがある場合、
基本的には SSH クライアントは自動選択してくれるらしいですが、
もしダメなときは ed25519 を指定できるみたいです：

```bash
$ echo 'IdentityFile ~/.ssh/id_ed25519' >> ~/.ssh/config
```

もし本当に「ed25519 以外は使わない」としたい場合：

```bash
$ echo 'IdentitiesOnly yes' >> ~/.ssh/config
```

詳しくは `man ssh_config` 参照。

ちなみに、GitHub に対して `git` コマンドを試すと、自動選択してくれました。


## 今の SSH 鍵の確認

```bash
$ \ls ~/.ssh/id_*.pub | xargs -n 1 ssh-keygen -l -f
```

行の先頭が鍵のビット長、行の最後がアルゴリズム名です。


## GitHub 疎通確認

https://help.github.com/articles/testing-your-ssh-connection/

```
$ ssh -T -p 22 -i ~/.ssh/id_ed25519 git@github.com
Enter passphrase for key '/home/hoge/.ssh/id_ed25519':
Hi seaoak! You've successfully authenticated, but GitHub does not provide shell access.
$
```


追記）
Windows の Sshfs Manager (ver 1.5.12.8) は、
新しい秘密鍵ファイル形式に対応していませんでした。
残念。

追記）
WinSCP (ver 5.9.3) は OpenSSH の新しいファイル形式に対応していませんでした。
使おうとすると PuTTY 形式 (`.ppk`) に変換しようとしてしまいます。
なので、ed25519 が使えるかどうかは未確認。
