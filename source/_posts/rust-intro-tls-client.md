---
title: Rust で SSL/TLS 通信をしてみる
date: 2024-08-17 14:18:05
tags:
 - Rust
---

Rust 勉強中です。

最近、スパムメールの数が増えてきてうざいので、受信メールのスパムチェックを自作しようと思って、メール受信処理を仲介する POP3 プロキシを作ってます。

POP3 サーバとの接続や、DNS over HTTPS (DoH) で、SSL/TLS 通信が必要になります。
Rust で SSL/TLS 通信をするにあたって、いくつかノウハウが得られたので、記事にします。

    OS:
      Windows 11 Pro (23H2)
    
    Rust toolchain:
      stable-x86_64-pc-windows-msvc (default)
      rustc 1.80.1 (3f5fd8dd4 2024-08-06)

## OS 標準の SSL/TLS 機能を使う

個人的な印象なのですが、OpenSSL を使うといろいろ罠を踏みやすいので、まずは Windows 標準の TLS 通信機能である SChannel を使ってみます。
なお、Linux では、OpenSSL が「標準機能」なので、OpenSSL が使われるみたいです。

`native-tls` クレートを使います。   
https://crates.io/crates/native-tls

コードの流れは単純で、最初に `TcpStream` を作って、それを `TlsConnector` に渡して、`TlsStream` を得ます。
この `TlsStream` は `Read` や `Write` を実装しているので、`read()` や `write_all()` などが使えます。

ちなみに、単純に `read_to_string()` とかを呼ばずに `read()` を繰り返し呼んでいるのは、
POP3 プロトコルが「行単位」のプロトコルだからです。
コネクションを維持したまま「１行だけ読み込み」とかしたいわけです。

```toml
native-tls = "0.2.12"
```

```rust
use std::io::{Read, Write, ErrorKind};
use std::net::TcpStream;

use anyhow::{anyhow, Result};
use native_tls::TlsConnector;

pub fn test_native_tls() -> Result<()> {
    let username = "foo@example.com";
    let hostname = "pop3.example.com";
    let port = 995;

    let connector = TlsConnector::new()?;
    let tcp_stream = TcpStream::connect((hostname.to_string(), port))?;
    let mut tls_stream = connector.connect(hostname, tcp_stream)?;

    let mut buf = Vec::new();
    read_some_lines(&mut tls_stream, &mut buf)?;
    println!("Greeting message from server: {}", String::from_utf8_lossy(&buf));

    println!("issue USER command");
    tls_stream.write_all(format!("USER {}\r\n", username).as_bytes())?;
    tls_stream.flush()?;

    let mut buf = Vec::new();
    read_some_lines(&mut tls_stream, &mut buf)?;
    println!("Response from server: {}", String::from_utf8_lossy(&buf));

    Ok(())
}

fn read_some_lines<R: Read>(reader: &mut R, buf: &mut Vec<u8>) -> Result<()> {
    let mut local_buf = [0u8; 1024];
    loop {
        let nbytes = match reader.read(&mut local_buf) {
            Ok(0) => return Err(anyhow!("steam is closed unexpectedly")),
            Ok(len) => len,
            Err(ref e) if e.kind() == ErrorKind::Interrupted => continue,
            Err(e) => return Err(anyhow!(e)),
        };
        buf.extend(&local_buf[0..nbytes]);
        if ends_with_u8(buf, b"\r\n") { // allow empty line
            break;
        }
    }
    Ok(())
}
```

## rustls を使う

せっかく Rust でプログラムを書くなら、Rust で書かれた TLS ライブラリを使いたい！ という気持ちがありました。
あと、`reqwest` クレートで HTTP/2 を使いたい場合は `rustls` を使うのがいいらしい。
というわけで、`rustls` クレートを使ってみます。   
https://crates.io/crates/rustls

SSL サーバ証明書の検証のためのルート証明書ストアは、OS 標準のものや、Mozilla (Firefox) が使っているものが利用できます。
とりあえず、OS 標準のルート証明書ストアを使ってみます。

`rustls-native-certs` クレートを使います。   
https://crates.io/crates/rustls-native-certs

ひとつ罠として、環境変数 `SSL_CERT_FILE` を定義していると、システムの設定ではなくてそのファイルを参照してしまうので、注意です。
わたしは、たまたま、OpenSSL の動作確認をしていた関係でこの環境変数を定義したままになっていて、ハマりました。

```toml
rustls = "0.23.12"
rustls-native-certs = "0.7.1"
```

```rust
use std::io::{Read, Write, ErrorKind};
use std::net::TcpStream;
use std::sync::Arc;

use anyhow::{anyhow, Result};
use rustls;
use rustls_native_certs;

pub fn test_tls() -> Result<()> {
    let username = "foo@example.com";
    let hostname = "pop3.example.com";
    let port = 995;

    let tls_root_store = {
        // use "rustls-native-certs" crate
        let mut roots = rustls::RootCertStore::empty();
        for cert in rustls_native_certs::load_native_certs()? {
            roots.add(cert).unwrap();
        }
        roots
    };
    let tls_config = Arc::new(
        rustls::ClientConfig::builder()
            .with_root_certificates(tls_root_store)
            .with_no_client_auth()
    );
    let host = hostname.to_string().try_into().unwrap();
    let mut tls_connection = rustls::ClientConnection::new(tls_config, host)?;
    let mut tcp_socket = TcpStream::connect(format!("{}:{}", hostname, port))?;
    let mut tls_stream = rustls::Stream::new(&mut tls_connection, &mut tcp_socket);

    let mut buf = Vec::new();
    read_some_lines(&mut tls_stream, &mut buf)?;
    println!("Greeting message from server: {}", String::from_utf8_lossy(&buf));

    println!("issue USER command");
    tls_stream.write_all(format!("USER {}\r\n", username).as_bytes())?;
    tls_stream.flush()?;

    let mut buf = Vec::new();
    read_some_lines(&mut tls_stream, &mut buf)?;
    println!("Response from server: {}", String::from_utf8_lossy(&buf));

    Ok(())
}
```

しかし、`cargo build` すると、`aws-lc-sys` クレートのビルドでエラーになってしまいました。
「`cmake` が無いよ」とか言われています。

Windows 環境で `cmake` コマンドとかのビルドツール一式を準備するのは正直めんどくさいので、`rustls` が `aws-lc-sys` クレートを使わないようにします。
デフォルトでは、`rustls` は暗号処理のために `aws-lc-rc` を使うのですが、`ring` というのも使えるらしいのです。
というわけで、`Cargo.toml` で `default-features=false` と `features=["ring]` を指定してみます。

```toml
rustls = { version = "0.23.12", default-features = false, features = ["ring", "std"] }
```

これで `cargo build` が通りました。

しかし、実行してみると、`read()` でエラーが返ってきてしまいました。
エラーメッセージは `unexpected end of file` となっています。
[`rustls` のドキュメント](https://docs.rs/rustls/0.23.12/rustls/struct.Reader.html#method.read)を見ると、「TCP コネクションが突然切断されたときとかに `UnexpectedEOF` を返すよ」と書いてありました。

正直よくわかりません。

ネットで検索しても情報がないし、[`rustls` のサンプルコード](https://github.com/rustls/rustls/blob/main/examples/src/bin)の `simpleclient.rs` などは問題なく動作します。

サンプルコードの HTTP クライアントは動くので、POP3 サーバ側がなにか特殊な条件を持っているのかも？ と疑ってみましたが、思いつかず・・・。

しかし、あらためて `rustls` のドキュメントを眺めていたところ、"Crate features" の章に気になる記述がありました。   
https://docs.rs/rustls/0.23.12/rustls/#crate-features

> `tls12` (enabled by default): enable support for TLS version 1.2.
> Note that, due to the additive nature of Cargo features and because it is enabled by default, other crates in your dependency graph could re-enable it for your application.
> If you want to disable TLS 1.2 for security reasons, consider explicitly enabling TLS 1.3 only in the config builder API.

そうです。`Cargo.toml` で `default-features=false` を指定したために、本来はデフォルトで有効になっている TLS1.2 機能が無効化されていたのでした。
POP3 サーバが TLS1.3 に対応していなかったため、TLS コネクションが張れずに TCP 接続が切断されてしまっていたようです。

というわけで、`Cargo.toml` を以下のように修正：

```toml
rustls = { version = "0.23.12", default-features = false, features = ["ring", "std", "tls12"] }
```

無事に動作するようになりました！

## ルート証明書ストアを Mozilla (Firefox) のものに切り替える

`rustls-native-certs` クレートの代わりに `webpki-roots` クレートを使います。   
https://crates.io/crates/webpki-roots

先述のコードの `tls_root_store` を生成するコードを以下のように変えるだけ OK です。

```rust
let tls_root_store = {
    rustls::RootCertStore::from_iter(
        webpki_roots::TLS_SERVER_ROOTS
            .iter()
            .cloned(),
    )
};
```

## おまけ： HTTP/2 を使いたい

DoH (DNS over HTTPS) では、HTTP/2 を使うのがお約束らしいです。

- Make API requests to 1.1.1.1 over DoH   
  https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-https/make-api-requests/

> HTTP/2 is, in fact, the minimum recommended version of HTTP for use with DNS over HTTPS (DoH)

`reqwest` クレートで HTTPS/2 を使うには、`rustls` を使った上でリクエストにバージョン指定をすれば良いらしい：

- Reqwestでhttp/2通信するときの注意(Rust)   
  https://zenn.dev/scirexs/articles/0b7a2de9817e31

> ・もしくは[作者の案内](https://github.com/seanmonstar/reqwest/issues/1666)の通り、TLS機能として`rustls`を指定するとhttp/2を使用できる

実際にコードを書いてみると、以下のようになります。

```rust
let client = reqwest::Client::builder()
    .use_rustls_tls()
    .https_only(true)
    .build()
    .unwrap();
let response = client.get(url).version(Version::HTTP_2).send().await;
println!("response.version(): {:?}", response.version());
let text = response.text().await?;
```

有用な情報に感謝！！
