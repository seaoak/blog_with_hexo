---
title: Node.js めも
date: 2016-11-06 22:00:00
updated: 2017-01-24 00:00:00
tags:
---

- https://nodejs.org/ja/
- https://github.com/creationix/nvm


## 導入

最初に nvm を導入する：

```
$ curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
$ cat >> ~/.bashrc

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
$
```

続いて、Node.js 本体をインストールする：

```
$ nvm ls-remote
$ nvm install stable
$ node -v
```

## 依存パッケージをインストール

カレントディレクトリにある `package.json` の設定にしたがって、ローカル（カレントディレクトリ直下の `node_modules` ディレクトリ）に依存パッケージをインストールできます。

普通に使うだけなら "dependencies" の依存パッケージのみインストールすればよい：

```
$ npm install
```

"devDependencies" の依存パッケージをインストールしたいときはオプションが必要：

```
$ npm install --only=dev
```
