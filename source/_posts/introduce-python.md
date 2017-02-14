---
title: Python の導入（root 権限なし）
date: 2017-01-12 15:19:06
updated: 2017-01-12 15:19:06
tags:
---
Let's Encrypt のクライアントを動かすのに python が必要らしいので、導入。

perlbrew などのように、ローカルに切り替えられるようにしたい。
python の場合は pyenv と virtualenv を使うらしい。

 - pyenv および virtualenv の使い方 https://www.qoosky.io/techs/0cf33bd9ac

とりあえず、前準備をします（※ここだけ root 権限が必要ですすみません）

```
$ sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils
```

まず、pyenv を入れる： https://github.com/yyuu/pyenv

```
$ git clone https://github.com/yyuu/pyenv.git ~/.pyenv
$ echo >> ~/.bash_profile
$ echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
$ echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
$ echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
```

続いて、pyenv-virtualenv を入れる： https://github.com/yyuu/pyenv-virtualenv

```
$ git clone https://github.com/yyuu/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
$ echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bash_profile
```

ここで新しいログインシェルを起動すると `pyenv` コマンドが使えるようになる。
とりあえず 2.x 系の最新版を入れておく：

```
$ pyenv install -l
$ pyenv install 2.7.13
$ pyenv rehash
$ pyenv versions
$ pyenv shell 2.7.13
$ pyenv versions
$ python -V
$ pyenv exec pip install --upgrade pip
```

以上。
