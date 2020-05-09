---
title: Let's Encrypt の ACMEv2 対応
date: 2020-05-09 16:20:23
tags:
---

以前、記事にしたように、このサイトでは Let's Encrypt の SSL 証明書を利用させていただいています。

 ⇒ {% post_link introduce-letsencrypt %}

ところが、先日、Let's Encrypt 運営から通知メールが届きました。
今年6月でサービス提供を終える古い認証プロトコルをまだ使っているよ、とのこと。
具体的に言うと、ACMEv1 というプロトコルのサポートが廃止になり、
今後は ACMEv2 のみ提供されるそうです。

とりあえず証明書の取得に利用しているツールを最新版にアップデートすれば、
自動的に ACMEv2 プロトコルに切り替わってくれるみたい。
もちろん、「せっかく ACMEv2 を使うならワイルドカード証明書がほしい」とかいう場合は
いろいろ作業が必要となりますが、ACMEv1 から ACMEv2 への切り替えだけならば簡単そう。

証明書の取得に利用させていただいている simp_le という Python 製ツールは、
しらばく前から ACMEv2 に対応してくれていました！ 感謝！！

https://github.com/zenhack/simp_le

以下、作業ログです。

---------------------------------------------------------------------

simp_le 最新版を使うためには、Python を 2.7 系から 3.6 系にアップデートしなければならない。

古い pyenv 設定を消しておく

```bash
$ rm ~/run/simp_le/.python-version
```

python3 系の最新版 (3.6.1) を入れる：

```bash
$ pyenv install -l
$ pyenv install 3.6.1
$ pyenv rehash
$ pyenv global 3.6.1
$ pyenv exec pip install --upgrade pip
$ python -V
```

GitHub から simp_le の最新版を取得：

```bash
$ cd ~/run/simp_le
$ git pull
$ git tag
$ git checkout 0.18.0
```

venv.sh 相当のことを手動でやる：

```bash
	$ pyenv virtualenv venv-simp_le
	$ pyenv virtualenvs
	$ pyenv versions
	$ pyenv local venv-simp_le
	$ pyenv virtualenvs
	$ pyenv versions

	$ pyenv exec pip list
	$ pyenv exec pip install -U setuptools
	$ pyenv exec pip install -U pip
	$ pyenv exec pip install -U wheel
	$ pyenv exec pip install -e .
	$ pyenv exec pip list
```

証明書ファイルのあるディレクトリで、お試し実行：

```bash
$ MAIL='foo@example.jp'
$ FQDN='bar.example.jp'
$ DOCROOT='/var/www/bar.example.jp/letsencrypt'
$ simp_le -v --email "$MAIL" -f account_reg.json -f account_key.json -f cert.pem -f chain.pem -f fullchain.pem -f key.pem -d "$FQDN:$DOCROOT"
```

あとしまつ（自作の自動更新スクリプトがエラーになるのでお掃除）：

```bash
$ rmdir /var/www/bar.example.com/letsencrypt/.well-known/acme-challenge
```

simp_le を実行すると、一発目は「更新する必要がありません」になってファイルは更新されず。
全部のファイル `*.pem` `*.json` を削除して再実行したら、証明書を再取得してくれました。
simp_le の ver. 0.15.0 で追加されたファイル `account_reg.json` も自動生成されました。

取得した証明書ファイルを Web サーバに配置したところ、正しくブラウザからアクセスできました。
ちゃんと発行日が今日の日付になっている SSL 証明書もブラウザ上で確認できました。

完了！
