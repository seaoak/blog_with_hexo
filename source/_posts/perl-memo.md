---
title: Perl めも
date: 2017-01-23 00:19:47
tags:
---

 - https://perlbrew.pl
 - https://github.com/perl11/cperl


## 導入

```bash
$ \curl -L https://install.perlbrew.pl | bash
$ echo 'source ~/perl5/perlbrew/etc/bashrc' >> ~/.bashrc
$ bash
$ perlbrew list
$ perlbrew available
$ perlbrew available | grep -E '^  perl-5\.[1-9]?[02468]\.' | nice -19 xargs -n 1 perlbrew install
$ perlbrew list
$ perlbrew switch perl-5.24.1
$ perl -v
$ perlbrew install-cpanm
```

アップデート

```bash
$ perlbrew self-upgrade
```


## CPAN モジュールのローカルインストール

```bash
$ cpanm -L lib URL::Encode
```


## おやくそく

```perl
#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use lib './lib/lib/perl5';

use Carp qw/confess/;

use Data::Dumper;
$Data::Dumper::Purity = 1;
```


## 定数を使う

http://d.hatena.ne.jp/fbis/20090612/1244806476

```perl
use constant DNS_SERVER_LIST => [
    '8.8.8.8',          # Google Public DNS
    '8.8.4.4',          # Google Public DNS
    ''                  # default
];
use constant DNS_ROUND_ROBIN_LIMIT => 10;

my @result;
foreach my $server (@{DNS_SERVER_LIST()}) {
    push(@result, nslookup($fqdn, $server, DNS_ROUND_ROBIN_LIMIT));
}
```


## Encode モジュールの罠

`Encode::encode()` や `Encode::decode()` で第3引数に `Encode::FB_CROAK`
を指定すると、第2引数に指定した文字列を破壊するらしい。

> CAVEAT: the input scalar STRING might be modified in-place depending on what is set in CHECK.

 - http://search.cpan.org/dist/Encode/Encode.pm#LEAVE_SRC
 - http://ks0608.hatenablog.com/entry/2012/03/06/144149
 - http://blog.livedoor.jp/dankogai/archives/51231739.html

したがって、次のようにやると元の文字列 `@nslookup_raw` が破壊されます。
実際には、長さゼロの文字列の配列になってしまいました。

```perl
my @nslookup_raw = `nslookup -type=A $host 2>&1`;
my @nslookup =
    map {s/\r?\r\n$/\n/; $_}
    map {use Encode qw/decode/; decode("shiftjis", $_, Encode::FB_CROAK)}
    @nslookup_raw;
```

とりあえず次のように定義して使うのが安全っぽい。

```perl
sub decode {
    use Encode qw//;
    return Encode::decode("shiftjis", shift, Encode::FB_CROAK | Encode::LEAVE_SRC);
}

sub encode {
    use Encode qw//;
    return Encode::encode("UTF-8", shift, Encode::FB_CROAK | Encode::LEAVE_SRC);
}
```


## 半角カナを全角カナに変換

```perl
    sub hankaku2zenkaku {
        use Lingua::JA::Regular::Unicode;
        return katakana_h2z(shift);
    }
```


### encodeURIComponent

```perl
    sub encode_uri_component {
        use URL::Encode qw//;
        return URL::Encode::url_encode_utf8(shift);
    }
```
