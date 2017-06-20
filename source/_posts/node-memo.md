---
title: Node.js めも
date: 2016-11-06 22:00:00
updated: 2017-01-24 00:00:00
tags:
---

- https://nodejs.org/ja/
- https://github.com/creationix/nvm


## 導入

```bash
$ curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
$ cat >> ~/.bashrc

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
$
$ nvm install stable
$ node -v
```
