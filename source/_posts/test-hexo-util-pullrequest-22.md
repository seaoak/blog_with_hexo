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
以上。
