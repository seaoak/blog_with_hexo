---
title: Let's Encrypt の導入（root 権限なし）
date: 2017-01-12 19:26:45
updated: 2017-01-12 19:26:45
tags:
---
独自ドメインを全面的に HTTPS 化するべく、
無料で発行してもらえる Let's Encrypt のサーバ証明書を導入しました。

 - 本家 Let's Encrypt https://letsencrypt.org
 - 公式ツール Certbot https://certbot.eff.org
 - 解説記事： [無償SSLサーバー証明書Let's Encryptの普及とHTTP/2および常時SSL化 - OSDN Magazine](https://mag.osdn.jp/16/06/28/090000)

ドキュメントによるとサーバの root 権限が必要とのことですが、
個人的な趣味としてそれは避けたい。

 - Web サーバを実行するユーザに sudo 権限を与えたくない
 - Web サーバの設定ファイルを自動的に書き換えられるのはイヤ（そもそも H2O は非対応ですが）
 - 証明書ファイル (key file / cert file) はローカルに作成できれば十分

というわけで、なにか手を考えないといけません。

[Certbot のドキュメント](https://certbot.eff.org/docs/intro.html#system-requirements)で、
root 権限を使わない ACME client が紹介されています：

 - letsencrypt-nosudo https://github.com/diafygi/letsencrypt-nosudo
 - simp_le https://github.com/kuba/simp_le

README を読むと letsencrypt-nosudo は root 権限での手作業が必要とのことなので、
全自動化できそうな simp_le を試しました。

 - 本家 https://github.com/kuba/simp_le
 - 解説記事 https://blog.heckel.xyz/2015/12/04/lets-encrypt-5-min-guide-to-set-up-cronjob-based-certificate-renewal/
 - 解説記事 https://blog.nytsoi.net/2016/01/08/automating-letsencrypt-with-simp_le

まず、各ドメインのドキュメントルートの直下に
`.well-known` というディレクトリがあり（なければ作り）、
そのディレクトリへの書き込み権限があることが前提です。
また、そのディレクトリ内のファイル／ディレクトリに対して外部から
（Let's Encrypt のサーバから）
TCP 80 番ポートで HTTP GET できなければなりません。
HTTPS ではないので注意。
全面的に HTTPS 化する場合、すべての HTTP アクセス（80番ポート）を
HTTPS （443番ポート）に 301 リダイレクトすることがあると思いますが、
`/.well-known` 配下へのアクセスだけはリダイレクトから除外します。
H2O の場合、`h2o.conf` で次のようにします：

```
hosts:
  "example.com:443":
    paths:
      "/":
        file.dir: /path/to/doc-root
  "example.com:80":
    paths:
      "/":
        redirect:
          url: "https://example.com/"
          status: 301
      "/.well-known":
        file.dir: /path/to/doc-root/.well-known
```

ちなみに、H2O ではデフォルトで `/.well-known` 配下がそのまま見えました。
H2O は隠しファイル（名前がドットで始まるもの）を特別扱いしないようです。

さて、ここからは simp_le のインストールの話です。

simp_le の公式ドキュメントでは `bootstrap.sh` を
root 権限 (sudo) で実行するようにと書かれていますが、
中身は apt-get install だけなので、手動でやれば十分です
（ここだけ root 権限が必要ですすみません）。
また、今回は pyenv / pyenv-virtualenv を利用したかったので、
`venv.sh` も中身を見て手動で実行しました。

python の初期設定については過去記事「{% post_link introduce-python %}」を参照してください。


まず、`bootstrap.sh` 相当のことを手動でやる：

```
$ sudo apt-get install -y ca-certificates gcc libssl-dev libffi-dev python python-dev
$ cd
$ git clone https://github.com/kuba/simp_le.git
$ cd simp_le
$ pyenv shell 2.7.13
```

次に、`venv.sh` 相当のことを手動でやる：

```
$ pyenv virtualenv --no-site-packages venv-simp_le
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

PATH はすでに通ってるので、設定不要でした。

ヘルプはちゃんと読みましょう：

```
$ simp_le --help
```

以上で simp_le のインストールは完了です。

続いて、証明書を新規に取得します。

解説記事を読むと
`account_key.json` をあらかじめ用意しないといけないように思えますが、
不要です。
`-f` オプションで指定するファイルはすべて simp_le が生成してくれます。
simp_le を最初に実行するディレクトリは空でよい。

```
$ cd ~/h2o
$ mkdir letsencrypt
$ cd letsencrypt
$ pyenv local venv-simp_le
$ simp_le -v --email 'foobar@example.com' -f account_key.json -f cert.pem -f chain.pem -f fullchain.pem -f key.pem -d example.com:../doc-root-1 -d www.example.com:../doc-root-2 -d blog.example.com:../doc-root-3
```

ここで、エラーになってしまいました。

```
DeserializationError: Deserialization error: Wrong directory fields

Unhandled error has happened, traceback is above

Debugging tips: -v improves output verbosity. Help is available under --help.
```

GitHub の Issue#114 に従って `--tos_sha256` オプションを追加してみる：    
https://github.com/kuba/simp_le/issues/114#issuecomment-236744611

```
$ simp_le -v --tos_sha256 6373439b9f29d67a5cd4d18cbc7f264809342dbf21cb2ba2fc7588df987a6221 --email 'foobar@example.com' -f account_key.json -f cert.pem -f chain.pem -f fullchain.pem -f key.pem -d example.com:../doc-root-1 -d www.example.com:../doc-root-2 -d blog.example.com:../doc-root-3
```

しかし変わらず。

ここで、GitHub の Issue を追っていると、
Fork して修正してくださったものを見つけました。感謝！！

https://github.com/zenhack/simp_le

```
$ cd
$ pyenv virtualenv-delete venv-simp_le
$ rm -rf simp_le
$ git clone https://github.com/zenhack/simp_le.git
$ cd simp_le
$ pyenv virtualenv --no-site-packages 2.7.13 venv-simp_le
$ pyenv virtualenvs
$ pyenv versions
$ pyenv local venv-simp_l
$ pyenv virtualenvs
$ pyenv versions
$ pyenv exec pip list
$ pyenv exec pip install -U setuptools
$ pyenv exec pip install -U pip
$ pyenv exec pip install -U wheel
$ pyenv exec pip install -e .
$ pyenv exec pip list
$ cd ~/h2o/letsencrypt
$ ls -a    ←中身は `.python-version` のみ
$ simp_le -v --email 'foobar@example.com' -f account_key.json -f cert.pem -f chain.pem -f fullchain.pem -f key.pem -d example.com:../doc-root-1 -d www.example.com:../doc-root-2 -d blog.example.com:../doc-root-3
```

今度は成功！　インタラクティブな問い合わせとか無くて、全自動で完了です。

カレントディレクトリに `-f` オプションで指定した5個のファイルが生成されています。

```
$ ls -1
account_key.json
cert.pem
chain.pem
fullchain.pem
key.pem
$
```

あとは `h2o.conf` に次のように指定してあげて `kill -HUP` すれば OK。

```
listen:
  port: 443
  ssl:
    certificate-file: letsencrypt/fullchain.pem
    key-file: letsencrypt/key.pem
```

ついでに自動更新スクリプトも作成。
[解説記事の `update_cert.sh`](https://blog.nytsoi.net/2016/01/08/automating-letsencrypt-with-simp_le) を参考にさせていただきました。

⇒ {% asset_link update_cert.sh.20170113a.txt %}

`rotatelogs` コマンドが無い人は `apt-get install -y apache2-utils` で入ります。

Certbot のドキュメントで一日2回やることを推奨しているので、crontab を設定：    
https://certbot.eff.org/#ubuntuxenial-other

```
$ crontab -l
13 10 * * * /home/foobar/h2o/letsencrypt/update_cert.sh
37 23 * * * /home/foobar/h2o/letsencrypt/update_cert.sh
$
```

以上、root 権限なしで Let's Encrypt のサーバ証明書が取得できました。
