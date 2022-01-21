---
title: Rust の HTML テンプレートエンジンを選ぶ
date: 2022-01-21 19:59:54
tags:
  - Rust
---

Rust で使える HTML テンプレートエンジンを探してみました。

「HTML テンプレートエンジン」というのは、ブログサイトとかの生成ツールが使っている便利なしくみです。
HTML ファイルを生成するときに全部プログラムで生成するのは大変なので、
あらかじめテキストファイルで HTML ファイルの「ひな形」（テンプレート）を作っておいて、
その中に、プログラムから値を埋め込むための印（プレースホルダー）を書いておきます。
テンプレートエンジンは、そのひな形を読み込んで、プログラムから渡されたデータでプレースホルダーを書き替えます。

テンプレートの書式もいろいろあって、基本的にはテンプレートエンジンによって異なります。
もちろん、複数のプログラミング言語でのエンジン実装が作られているテンプレート書式もあります。
基本的な書式は一緒だけど、エンジン実装ごとに微妙に仕様が違う、というのもあります。

ぱっと思いつくだけでも、テンプレートエンジンはたくさんあります：

- [Pug](https://pugjs.org) -- 旧称「Jade」。JavaScript がメインっぽいけど、いろんな言語での実装がある。
- [Nunjucks](https://mozilla.github.io/nunjucks/) -- JavaScript 製エンジン。
- [EJS](https://ejs.co) -- これも JavaScript 製エンジン。
- [Jinja](https://jinja.palletsprojects.com) -- Python 製エンジン。
- [Django](https://www.djangoproject.com) -- これも Python 製エンジン。
- [Handlebars](https://handlebarsjs.com) -- JavaScript と Rust の実装があるみたい。Rust の公式ドキュメントとかでも使われているらしい。
- [Tera](https://tera.netlify.app) -- Rust 製エンジン。Jinja2 と Django からの派生とのこと。

今回は、Rust で作っているプログラムで使いたいので、Rust 製エンジンを選びます。

とりあえず、[crate.io](https://crates.io) で人気のあるクレートを探してみる。   
https://crates.io/search?q=template%20html&sort=downloads

tinytemplate とか handlebars とか tera とか Askama とか liquid とか出てきますね。
ほかにも、[Seilfish](https://sailfish.netlify.app) とか [Dojang](https://crates.io/crates/dojang) とかありました。

今回は、可能であれば、JavaScript 製エンジンもあるテンプレート書式を選びたいと思っています。
というのも、もともと Node.js で動くブログ構築アプリケーション [Hexo](https://hexo.io) を利用しているので、
テンプレートファイルも共通化できたらうれしいのです。

ついでに言うと、

- オリジナルのヘルパー関数を定義して使いたい（できればクロージャーが使えるとうれしい）
- テンプレートはコンパイル時ではなく実行時に読み込みたい（テンプレートの作成が楽になるので）

とかいうリクエストもあります。

今回は、Tera と Handlebars を試してみることにしました。

## Tera を試す

- Tera   
  https://tera.netlify.app
- tera - crates.io   
  https://crates.io/crates/tera
- GitHub - Keats/tera: A template engine for Rust based on Jinja2/Django   
  https://github.com/Keats/tera

とりあえず、テンプレートエンジンにデータを渡す方法と、
オリジナルのヘルパー関数を定義して使う方法を調べました。

テンプレートファイルを書いてみると、こんなかんじ：

```tera
This is a sample for {{ person.first_name }}.

list:
{% for x in people -%}
  {{loop.index}}. {{x.first_name}} / {{x.last_name}}
{% endfor %}

helper:
{{ my_helper(name="Alice") }}
{{ my_helper(name="Bob") }}
```

んで、書いてみた Rust コードが以下のもの：

```rust
use std::collections::HashMap;

use serde::Serialize;
use tera::{Context, Tera};

#[derive(Debug, Clone, Serialize)]
struct Person {
    first_name: String,
    last_name: String,
}

#[derive(Debug, Clone, Serialize)]
struct Locals {
    people: Vec<Person>,
}

fn main() {
    println!("Hello, world!");

    let mut tera = match Tera::new("templates/**/*.html") {
        Ok(t) => t,
        Err(e) => {
            eprintln!("Tera parsing error: {:?}", e);
            std::process::exit(1);
        }
    };
    tera.autoescape_on(vec![]); // disable auto-escaping

    let locals = Locals {
        people: vec![
            Person {
                first_name: "Alice".into(),
                last_name: "1990".into(),
            },
            Person {
                first_name: "Bob".into(),
                last_name: "1980".into(),
            },
        ],
    };
    let mut context = Context::new();
    context.insert("person", &locals.people[0]);
    context.insert("people", &locals.people);

    {
        let target = locals.people[0].clone();
        let unknown = Person {
            first_name: "Unknown".into(),
            last_name: "0".into(),
        };
        tera.register_function("my_helper", Box::new(move |args: &HashMap<String, tera::Value>| -> tera::Result<tera::Value> {
            let arg = match args.get("name") {
                Some(v) => match tera::from_value::<String>(v.clone()) {
                    Ok(v) => v,
                    Err(_) => return Err("my_helper: invalid argument".into()),
                },
                None => return Err("my_helper: one argument should be specified".into()),
            };
            let person = if arg == target.first_name {
                &target
            } else {
                &unknown
            };
            Ok(tera::to_value(format!("{:?}", person)).unwrap())
        }));
    }

    let output = tera.render("index.html", &context).expect("Tera render error");
    println!("{}", output);
}
```

ちなみに、Rust の `Cargo.toml` には以下の依存クレート指定が必要です：

```toml
serde = { version = "1.0.134", features = ["derive"] }
serde_json = "1.0.75"
tera = "1"
```

やりたかったことは、ひととおりできそうな感じです。
ただ、ヘルパー関数を呼び出すときの書式がちょっと好きじゃないかも。
`my_helper(name="Bob")` という「名前付き引数」指定が必須なのが、ちょっと冗長な気がする。

## Handlebars を試す

- Handlebars   
  https://handlebarsjs.com
- handlebars - crates.io   
  https://crates.io/crates/handlebars
- GitHub - sunng87/handlebars-rust: Rust templating with Handlebars   
  https://github.com/sunng87/handlebars-rust

テンプレートファイルを書いてみる：

```handlebars
This is a sample for {{ person.first_name }}.

list:
{{#each people }}
  {{@index}}. {{this.first_name}} / {{this.last_name}}
{{/each }}

helper:
{{my_helper "Alice" }}
{{my_helper "Bob" }}
```

Rust のコード：

```rust
use anyhow::Result;
use handlebars::{Context, Handlebars, Helper, JsonRender, HelperResult, RenderContext, RenderError, Output};
use serde::Serialize;

#[derive(Debug, Clone, Serialize)]
struct Person {
    first_name: String,
    last_name: String,
}

#[derive(Debug, Clone, Serialize)]
struct Locals {
    person: Person,
    people: Vec<Person>,
}

fn main() -> Result<()> {
    println!("Hello, world!");

    let mut handlebars = Handlebars::new();
    handlebars.set_strict_mode(true);
    handlebars.set_dev_mode(true);
    handlebars.register_escape_fn(handlebars::no_escape); // disable HTML escaping

    handlebars.register_templates_directory(".html", "templates/")?;

    let locals = Locals {
        person:
            Person {
                first_name: "Charlie".into(),
                last_name: "2000".into(),
            },
        people: vec![
            Person {
                first_name: "Alice".into(),
                last_name: "1990".into(),
            },
            Person {
                first_name: "Bob".into(),
                last_name: "1980".into(),
            },
        ],
    };

    {
        let target = locals.people[0].clone();
        let unknown = Person {
            first_name: "Unknown".into(),
            last_name: "0".into(),
        };
        handlebars.register_helper("my_helper", Box::new(move |h: &Helper, _: &Handlebars, context: &Context, _: &mut RenderContext, out: &mut dyn Output| -> HelperResult {
            let arg = h.param(0).ok_or(RenderError::new("my_helper: one argument should be specified"))?;
            let arg = arg.value().render();
            let person = if arg == target.first_name {
                &target
            } else {
                &unknown
            };
            let val = context.data().get("person").unwrap().get("last_name").unwrap().render().parse::<usize>()?; // check a variable in the context
            out.write(&format!("{:?} and {:?}", person, val))?;
            Ok(())
        }));
    }

    let output = handlebars.render("index", &locals)?;
    println!("{}", output);
    Ok(())
}
```

Rust の `Cargo.toml` に書く依存クレートの指定：

```toml
[dependencies]
anyhow = "1.0.52"
handlebars = { version = "4.2.1", features = ["dir_source"] }
serde = { version = "1.0.134", features = ["derive"] }
serde_json = "1.0.75"
```

こちらも、とりあえずやりたかったことはできました。
独自のヘルパー関数に渡される情報（引数）が多いですね。
テンプレートの書式はちょっと Lisp っぽいところがありますが、キライではない。

## まとめ

今回は Handlebars を使ってみようと思います。
