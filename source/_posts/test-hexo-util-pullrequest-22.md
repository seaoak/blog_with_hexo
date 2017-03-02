---
title: hexo-util pull request 22
date: 1999-01-04 11:37:08
tags:
 - Test
---

※このページは Hexo の動作確認のためのものです。内容は無視してください。

------------------------------------------------------------------------------
## Pull Request

https://github.com/hexojs/hexo-util/pull/22

`hexo-util` の repository を git clone しただけではダメで、
`npm run build:highlight` を実行して `highlight_alias.json` を生成する必要がある。


------------------------------------------------------------------------------
## About `highlight.js`

 - https://highlightjs.org
 - https://www.npmjs.com/package/highlight.js
 - http://highlightjs.readthedocs.io/en/latest/
 - http://highlightjs.readthedocs.io/en/latest/building-testing.html
 - http://highlightjs.readthedocs.io/en/latest/api.html
 - http://highlightjs.readthedocs.io/en/latest/line-numbers.html
 - https://github.com/isagalaev/highlight.js
 - https://github.com/isagalaev/highlight.js/issues/1425

`highlight.js` の git repository を clone しただけでは node_modules として
使えないので注意。
`node tools/build.js -t node` を実行して生成された `build` ディレクトリを
`node_modules/highlight.js` とみなせばよい。

```bash
$ git clone ssh://git@github.com:22/isagalaev/highlight.js.git
$ cd highlight.js
$ node tools/build.js -t node
$ cd ../blog/node_modules
$ ln -s ../../highlight.js/build highlight.js
```

------------------------------------------------------------------------------
## multi-line comment

https://github.com/hexojs/hexo/pull/904

{% codeblock lang:javascript %}
/**
 * Test
 */
{% endcodeblock  %}

------------------------------------------------------------------------------
## multi-line comment including empty line

https://github.com/hexojs/hexo-util/pull/16

{% codeblock lang:javascript %}
/*

 */
{% endcodeblock  %}

------------------------------------------------------------------------------
## multi-line with autoDetect

{% codeblock %}
"use strict";
/*

 */
{% endcodeblock  %}

------------------------------------------------------------------------------
https://github.com/meteor/hexo-theme-meteor/issues/30

```js
import ApolloClient from 'apollo-client';
import { meteorClientConfig } from 'meteor/apollo';

const client = new ApolloClient(meteorClientConfig());
```

Unless the style `.line { height: 22.400000000000002px; }` is specified,
the line 3 (empty line) will look like it is removed.

------------------------------------------------------------------------------
## Is this a markdown parse error?

https://github.com/hexojs/hexo/issues/687

```json
{
    "name": "pajjket",
    "time": "2014-6-18 19:10:41",
    "done": true
}
```

------------------------------------------------------------------------------
以上。
