---
title: Rust で「まぎらわしいアルファベット」を検出したい
date: 2024-10-26 11:13:51
tags:
 - Rust
---

Rust のお勉強中です。勉強したことのアウトプットとして、スパムフィルター機能を備えた POP3 プロキシを作成しています。

スパムメール（迷惑メール）にはいろいろ特徴がありますが、そのひとつとして、「英語以外のまぎらわしいアルファベットを使っている」というものがあります。
たとえば、「AMAZON」の代わりに「AMAZОN」と書いてあったりします。アルファベットの「O」（オー）が違います。人間の目では区別できないですよね。

作成中のスパムフィルターでは、この特徴をスパムの指標のひとつとして使いたい。

ちなみに、Rust 標準ライブラリの `char` には、Unicode の文字種を判定する関数が用意されています。
関数 `char::is_alphabetic()` は、英語のアルファベットだけではなく、他の言語のアルファベットや、日本語の漢字ひらがなカタカナに対しても、`true` を返します。
Unicode での「アルファベット」は、とても意味が広いみたいですね。
また、関数 `char::is_ascii_alphabetic()` は、ASCII 文字のアルファベットに対してだけ `true` を返してくれます。

最初に考えた案は、Unicode の文字種（コードポイントの属する分類名？）を使えないか、というものです。
しかし、ちょっと調べたところでは、これを簡単に行う方法はなさそうでした。

次に、lingua クレートを使う案を考えました。
lingua クレート (https://crates.io/crates/lingua) は、与えられた文字列が「どの言語で書かれたものか？」を判定するクレートです。
このクレートの基本的な機能（使われている Unicode 文字の種類の判定）を使って、日本語と英語とそれ以外とを区別できるんじゃないか、と考えたわけです。
これはうまく動きました。書いてみたコードをこの記事の末尾に掲載しておきます。

しかし、なんというか、lingua クレートを使う案は、オーバーキル感が否めません・・・。

そこで、いま流行りの LLM な AI に質問してみることにしました。
[検索エンジン bing のページ](https://www.bing.com/)から [Copilot が簡単に使える](https://copilot.microsoft.com/)ので（ログインすら不要）、試してみました。
その結果、うまく動作する正規表現が得られました。

```rust
Regex::new(r"[\p{Alphabetic}&&[^\p{ASCII}\p{Hiragana}\p{Katakana}\p{Han}\p{Punct}ー]]").unwrap();
```

以下、Copilot とのやりとりをそのまま掲載します。ご参考まで！

## Copilot とのやりとり

{% blockquote %}
あなたは日本語で応答してください。あなたは Rust 言語のプログラマです。日本語と英語が混じった文字列について、英語以外のアルファベット（たとえばキリル文字）が含まれているかを判定する処理のソースコードを提示してください。
{% endblockquote %}

{% blockquote %}
了解しました！英語以外のアルファベットが含まれているかを判定する処理のRustコードをお見せしますね。

```rust
use regex::Regex;

fn contains_non_english_alphabets(s: &str) -> bool {
    // Unicodeの範囲に基づいて英語以外のアルファベットを判定
    let non_english_regex = Regex::new(r"[^\u0000-\u007F\u00A0-\u00FF\u0100-\u017F]").unwrap();
    non_english_regex.is_match(s)
}

fn main() {
    let text = "これはtestです"; // 例として日本語と英語の混在文字列
    if contains_non_english_alphabets(text) {
        println!("英語以外のアルファベットが含まれています。");
    } else {
        println!("英語以外のアルファベットは含まれていません。");
    }
}
```

このコードでは、正規表現を使用して英語以外のアルファベットが文字列に含まれているかどうかを判定します。キリル文字などの他のアルファベットもチェックできます。この例では、日本語と英語が混在する文字列を判定対象にしています。何か他に手伝えることはありますか？
{% endblockquote %}

{% blockquote %}
提示されたコードは誤っています。なぜなら、この正規表現では、日本語の文字（漢字など）もマッチしてしまうからです。修正案を提示してください。
{% endblockquote %}

{% blockquote %}
指摘ありがとうございます。それでは、日本語の文字（漢字など）を除外して、英語以外のアルファベットを判定する修正版のコードをお見せします。

```rust
use regex::Regex;

fn contains_non_english_alphabets(s: &str) -> bool {
    // 英語のアルファベットと日本語の文字を除外した正規表現
    let non_english_regex = Regex::new(r"[^\p{Latin}\p{Hiragana}\p{Katakana}\p{Han}]").unwrap();
    non_english_regex.is_match(s)
}

fn main() {
    let text = "これはtestです"; // 例として日本語と英語の混在文字列
    if contains_non_english_alphabets(text) {
        println!("英語以外のアルファベットが含まれています。");
    } else {
        println!("英語以外のアルファベットは含まれていません。");
    }
}
```

このコードでは、英語のアルファベット（Latin）と日本語の文字（ひらがな、カタカナ、漢字）を除外して、それ以外の文字が含まれているかどうかを判定します。これでキリル文字など他のアルファベットもチェックできます。また指摘などあれば教えてくださいね。
{% endblockquote %}

{% blockquote %}
提示されたコードの正規表現は、ピリオドなどの記号にもマッチしてしまいます。修正案を提示してください。
{% endblockquote %}

{% blockquote %}
その通りですね。ピリオドや他の記号を除外する修正案を示します。以下のコードでは、英語のアルファベット（Latin）、日本語の文字（ひらがな、カタカナ、漢字）、および基本的な記号を除外するようにしています。

```rust
use regex::Regex;

fn contains_non_english_alphabets(s: &str) -> bool {
    // 英語のアルファベット、日本語の文字、および記号を除外した正規表現
    let non_english_regex = Regex::new(r"[^\p{Latin}\p{Hiragana}\p{Katakana}\p{Han}\p{Punct}]").unwrap();
    non_english_regex.is_match(s)
}

fn main() {
    let text = "これはtestです。"; // 例として日本語と英語の混在文字列
    if contains_non_english_alphabets(text) {
        println!("英語以外のアルファベットが含まれています。");
    } else {
        println!("英語以外のアルファベットは含まれていません。");
    }
}
```

この修正版の正規表現は、句読点や記号を考慮しています。これでさらに精度が上がるはずです。何か他にお手伝いできることはありますか？
{% endblockquote %}

{% blockquote %}
提示されたコードの正規表現は、日本語の長音記号 「ー」にもマッチしてしまいます。修正案を提示してください。
{% endblockquote %}

{% blockquote %}
ありがとうございます。長音記号「ー」を除外するために、もう少し修正を加えます。

```rust
use regex::Regex;

fn contains_non_english_alphabets(s: &str) -> bool {
    // 英語のアルファベット、日本語の文字、句読点、基本的な記号、長音記号を除外した正規表現
    let non_english_regex = Regex::new(r"[^\p{Latin}\p{Hiragana}\p{Katakana}\p{Han}\p{Punct}ー]").unwrap();
    non_english_regex.is_match(s)
}

fn main() {
    let text = "これはtestですー。"; // 例として日本語と英語の混在文字列
    if contains_non_english_alphabets(text) {
        println!("英語以外のアルファベットが含まれています。");
    } else {
        println!("英語以外のアルファベットは含まれていません。");
    }
}
```

これで、日本語の長音記号「ー」も考慮されています。こちらでどうでしょうか？他にも修正が必要な点があれば教えてください。
{% endblockquote %}

{% blockquote %}
提示されたコードの正規表現は、ASCII 文字以外の英語アルファベットにもマッチしてしまいます。英語アルファベットについては ASCII 文字のみマッチするようにしてください。
{% endblockquote %}

{% blockquote %}
なるほど、ASCII文字のみの英語アルファベットにマッチするように正規表現を修正しました。

```rust
use regex::Regex;

fn contains_non_english_alphabets(s: &str) -> bool {
    // ASCII範囲の英語アルファベット、日本語の文字、句読点、基本的な記号、長音記号を除外した正規表現
    let non_english_regex = Regex::new(r"[^\x00-\x7F\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF\u3000-\u303Fー]").unwrap();
    non_english_regex.is_match(s)
}

fn main() {
    let text = "これはtestですー。"; // 例として日本語と英語の混在文字列
    if contains_non_english_alphabets(text) {
        println!("英語以外のアルファベットが含まれています。");
    } else {
        println!("英語以外のアルファベットは含まれていません。");
    }
}
```

これで、ASCII範囲の英語アルファベットのみにマッチするように修正されています。いかがでしょうか？他にも修正や質問があれば教えてくださいね。
{% endblockquote %}

{% blockquote %}
Rust 標準ライブラリの関数 char::is_alphabetic() に相当する正規表現を提示してください。
{% endblockquote %}

{% blockquote %}
`char::is_alphabetic()` に相当する正規表現は、Unicodeのアルファベット全体をカバーする必要があります。つまり、基本ラテン文字だけでなく、全ての国のアルファベットに対応することを意味します。以下のような正規表現がそれに該当します。

```rust
use regex::Regex;

fn contains_alphabetic_chars(s: &str) -> bool {
    // Unicodeのアルファベットに該当する正規表現
    let alphabetic_regex = Regex::new(r"\p{Alphabetic}").unwrap();
    alphabetic_regex.is_match(s)
}

fn main() {
    let text = "これはtestですー。"; // 例として日本語と英語の混在文字列
    if contains_alphabetic_chars(text) {
        println!("アルファベットが含まれています。");
    } else {
        println!("アルファベットは含まれていません。");
    }
}
```

この正規表現は、全てのUnicodeアルファベット文字をマッチします。これが `char::is_alphabetic()` に相当する処理となります。お試しください！他にも質問があれば教えてください。
{% endblockquote %}

{% blockquote %}
Rust で、正規表現 `[\p{Alphabetic}]` と正規表現 `[^\p{ASCII}]` の両方にマッチする文字列にマッチする単一の正規表現を提示してください。
{% endblockquote %}

{% blockquote %}
もちろんです。正規表現 `[\p{Alphabetic}]` はすべてのアルファベットにマッチし、`[^\p{ASCII}]` はASCII範囲外のすべての文字にマッチします。この両方にマッチする文字列を見つけるには、ASCII範囲外のアルファベットを対象にします。

以下の単一の正規表現がその目的を達成します：

```rust
use regex::Regex;

fn main() {
    let text = "Example 例 тест مثال"; // 例として様々なアルファベットを含む文字列
    let regex = Regex::new(r"[\p{Alphabetic}&&[^\p{ASCII}]]").unwrap();
    let matches: Vec<_> = regex.find_iter(text).collect();

    for m in matches {
        println!("{}", m.as_str());
    }
}
```

この正規表現は、`[\p{Alphabetic}&&[^\p{ASCII}]]` で、ASCII範囲外のアルファベット文字にマッチします。これでどうでしょうか？他に何かお手伝いできることはありますか？
{% endblockquote %}

以上を参考に、完成させたのが次の正規表現となります：

```rust
Regex::new(r"[\p{Alphabetic}&&[^\p{ASCII}\p{Hiragana}\p{Katakana}\p{Han}\p{Punct}ー]]").unwrap();
```

正規表現の中で文字クラスを指定するときに `&&` 記号を使って入れ子にできるということは、初めて知りました。
他の言語の正規表現エンジンでも使えるのかしら？？

ちなみに、Copilot が提案してきた「Unicode コードポイントの範囲を指定する」正規表現（`\u4E00-\u9FFF` とか）は、
`\p{Han}` という Unicode character class 指定に比べて当たり判定が小さいので、ダメです。
たとえば、漢字の「𠮷」（下の横棒が長い「𠮷野家」の字）がマッチしなくなってしまいます。

結論： Copilot は優秀だけど、提案された内容をちゃんと吟味できないとダメ

## lingua クレート使う案

当初、正規表現では無理だと考えたので、lingua クレートを使う方法を実装しました。

lingua クレート (https://crates.io/crates/lingua) は、与えられた文字列が「どの言語で書かれたものか？」を判定するクレートです。
このクレートの基本的な機能（使われている Unicode 文字の種類の判定）だけを使って、日本語と英語とそれ以外とを区別できるんじゃないか、と考えたわけです。

まず、lingua クレートのサンプルコードをそのまま使って、「すべての言語の中からどの言語の文字かを推定する」機能を使ってみました。

```rust
lazy_static! {
    static ref DETECTOR: lingua::LanguageDetector = lingua::LanguageDetectorBuilder::from_all_languages().build();
    static ref EXCEPTION_CHARS: Vec<char> = vec!['ー']; // these characters are "is_alphabetic()=true", but do not recognize a Japanese character
}

let is_suspicious_alphabet = |c: &char| {
    if !c.is_alphabetic() {
        return false;
    }
    if EXCEPTION_CHARS.contains(c) {
        return false;
    }
    // see https://crates.io/crates/lingua
    let lang = DETECTOR.detect_language_of(*c);
    let is_suspicious = match &lang {
        &Some(lingua::Language::English) => false,
        &Some(lingua::Language::Japanese) => false,
        _ => true,
    };
    if is_suspicious {
        println!("suspicious-alphabet: {} ({:?})", *c, lang);
    }
    is_suspicious
};
```

しかし、`from_all_language()` の結果は、安定しませんでした。
普通の ASCII アルファベットに対して、`English` 以外のいろいろな言語を返してきてしまいます。

そこで、選択肢を英語と日本語のみに限定して、判定させることにしました。
英語と日本語のそれぞれについて、「どれくらいその言語っぽいか」を数値化してもらい、その数値が十分大きければ OK、というようにしました。

```rust
lazy_static! {
    static ref LANGUAGES_FOR_DETECTOR: Vec<lingua::Language> = vec![lingua::Language::English, lingua::Language::Japanese];
    static ref DETECTOR: lingua::LanguageDetector = lingua::LanguageDetectorBuilder::from_languages(&LANGUAGES_FOR_DETECTOR).build();
    static ref EXCEPTION_CHARS: Vec<char> = vec!['ー']; // these characters are "is_alphabetic()=true", but do not recognize a Japanese character
}

let is_suspicious_alphabet = |c: &char| {
    if !c.is_alphabetic() {
        return false;
    }
    if EXCEPTION_CHARS.contains(c) {
        return false;
    }
    // see https://crates.io/crates/lingua
    let confidence_values = DETECTOR.compute_language_confidence_values(*c).into_iter().collect::<HashMap<lingua::Language, f64>>();
    let is_english = confidence_values[&lingua::Language::English] > 0.9;
    let is_japanese = confidence_values[&lingua::Language::Japanese] > 0.9;
    let is_ok = (is_english && c.is_ascii_alphabetic()) || is_japanese;
    if !is_ok {
        println!("suspicious-alphabet: {} ({:?})", *c, confidence_values);
    }
    !is_ok
};
```

これで、ちゃんとキリル文字とかを検出できるようになりました。

しかし、まぁ、文字種判定に lingua クレートを使うのは、オーバーキルもいいところだと思います。
計測はしていませんが、きっと処理も重いと思われます。

正規表現で実現できるなら、そのほうがいいですねー！
