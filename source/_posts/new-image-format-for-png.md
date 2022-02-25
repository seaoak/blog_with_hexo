---
title: PNG に代わるロスレス圧縮の画像フォーマットをさがす
date: 2022-02-24 15:06:30
tags:
---

データバックアップ用に 8TB ハードディスクを買ったので、ローカルディスクのフルバックアップをとったのですが、
コピーツール ([FastCopy](https://fastcopy.jp)) の画面を見ていて、あらためて「PNG ファイルがたくさんあるなぁ」と思い、
「もしかして WebP とか新しいフォーマットならもっと小さくなるのでは？」とひらめいて、ちょっと調べてみました。

結論としては、PNG をやめて WebP に移行することにしました。

{% asset_img table20220223a1.png %}

ちなみに、その大量の PNG ファイルは、オンラインゲーム FINAL FANTASY XIV (FF14) のスクリーンショットだったりします。
撮影には [Bandicam](https://www.bandicam.jp) を使っていて、BMP 形式で保存するようにしています（その場で PNG 圧縮すると連写ができなさそうなので）。
その BMP ファイルを、定期的に [ImageMagick](https://imagemagick.org) で PNG ファイルに変換（圧縮）しています。シェルスクリプトで一括変換。
FF14 は2013年からプレイしているので、現時点で 6.5万ファイルあって、総サイズは 412GB になります。
4K 解像度でプレイしているので、サイズがでかいです。
もちろん、非可逆圧縮の JPEG とかにしちゃえばもっと小さくなるのはわかっているのですが、**スクリーンショットは「思い出の記録」なのでロスレスは譲れない**のでした。

## はじめに

今回の調査の目的は、静止画イメージファイルのロスレス圧縮フォーマットで、PNG に代わる新しいものを探す、というものです。
扱う画像は「3D オンラインゲームのスクリーンショット」です。
4K (3840x2160) 解像度で、RGB 各 8bit （アルファチャネルなし）の画像です。
**一般の「写真」や「イラスト」や「文書」や「スライド」などでは異なる結果になる可能性があります**。

実験に使った画像は、BMP 形式で 23MB のものです。

{% asset_img sample_shrink.jpg "実験に使った画像（縮小版）" %}

⇒ {% asset_link sample.png "original PNG file (10MB)" %}

前提条件：

- Windows 10 で使えること。
- 画像ビューアー [XnView MP](https://www.xnview.com/en/xnviewmp/) で閲覧＆サムネイル生成ができること。
- 画像編集ソフト [GIMP](https://www.gimp.org) で読み書きできること。
- できれば、コマンドラインから実行できるとうれしい（シェルスクリプトで一括変換したい）。

実行環境：

    OS: Windows 10 Pro 64bit 21H2 (build 19044)
    CPU: AMD Ryzen Threadripper 2950X (16core/32thread, 3.5GHz)
    MEM: 32GB DDR4-3600
    SSD: Intel 760p (2TB)

ImageMagick のバージョンは `7.1.0-26 Q16-HDRI x64 2022-02-21` （の Portable 版）です：   

- ImageMagick – Download   
  https://imagemagick.org/script/download.php#windows   
  (`ImageMagick-7.1.0-portable-Q16-HDRI-x64.zip`)

```bash
$ convert -version
Version: ImageMagick 7.1.0-26 Q16-HDRI x64 2022-02-21 https://imagemagick.org
Copyright: (C) 1999-2021 ImageMagick Studio LLC
License: https://imagemagick.org/script/license.php
Features: Cipher DPC HDRI OpenCL
Delegates (built-in): bzlib cairo freetype gslib heic jng jp2 jpeg jxl lcms lqr lzma openexr pangocairo png ps raqm raw rsvg tiff webp xml zip zlib
Compiler: Visual Studio 2022 (193030709)
$
```

ちゃんと「ロスレス」圧縮になっているかの確認には、ImageMagick の `compare` コマンドを使います。
メトリクス `AE` を指定して、ピクセル単位で一致しない箇所を数えてもらいます。
出力が `0` なら、完全一致（＝ロスレス）ということになります。

```bash
$ compare -metric AE aaa.bmp aaa.png NULL:
0
$
$ compare -metric AE aaa.bmp aaa.jpg NULL:
7.97697e+06
$
```

参考情報にしたサイト：

- Lossless Image Formats Comparison (WebP, Jpeg XL, AVIF, PNG) : AV1   
  https://www.reddit.com/r/AV1/comments/fjddcj/lossless_image_formats_comparison_webp_jpeg_xl/
- Report   
  https://eclipseo.github.io/image-comparison-web/report.html

## WebP をためしてみる

WebP は、Google が開発した画像フォーマットで、動画圧縮コーデック VP8 の技術を利用して圧縮するものです。

- WebP - Wikipedia   
  https://ja.wikipedia.org/wiki/WebP
- ImageMagick と WebP - Qiita   
  https://qiita.com/yoya/items/0848a6b0b39db4cd57c2
- WebP Lossless はちゃんと Lossless してます - Qiita   
  https://qiita.com/yoya/items/a000c2e123d448a37f47
- ImageMagick - WebP Encoding Options   
  https://imagemagick.org/script/webp.php

まずは、なにもオプションを指定せずに ImageMagick で変換してみる：

```bash
$ convert aaa.bmp aaa.webp
```

ロスレスかどうか、チェックをしてみる：

```bash
$ compare -metric AE aaa.bmp aaa.webp NULL:
8.20354e+06
$
```

デフォルトではロスレス圧縮にならない模様。

今度は明示的にロスレス圧縮の指定してみる：

```bash
$ time convert aaa.bmp -define webp:lossless=true ccc.webp

real    0m7.564s
user    0m0.000s
sys     0m0.015s
$
$ du -sk aaa.png ccc.webp
9964    aaa.png
7448    ccc.webp
$
$ compare -metric AE aaa.bmp ccc.webp NULL:
0
$
```

ちゃんとロスレス圧縮になりました。PNG 形式に比べてファイルサイズが 76% に小さくなっていますね。優秀！

なお、WebP に変換する際に `-quality 99` とか指定してみても、ファイルサイズの差はわずかでした：

```bash
$ time convert aaa.bmp -quality 99 -define webp:lossless=true ddd.webp

real    0m8.778s
user    0m0.015s
sys     0m0.016s
$
$ du -sk aaa.png ccc.webp ddd.webp
9964    aaa.png
7448    ccc.webp
7344    ddd.webp
$
```

## AVIF をためしてみる

AVIF (AV1 Image File Format) は、動画圧縮コーデック VP1 の技術を使って圧縮する画像フォーマットです。

- AV1 - Wikipedia   
  https://ja.wikipedia.org/wiki/AV1#AV1_Image_File_Format%EF%BC%88AVIF%EF%BC%89

まずは ImageMagick を使って変換してみます。

```bash
$ time convert aaa.bmp -quality 100 ccc.avif

real    0m24.906s
user    0m0.000s
sys     0m0.015s
$
$ du -sk ccc.avif
4816    ccc.avif
$
$ compare -metric AE aaa.bmp ccc.avif NULL:
7.13956e+06
$
```

`-quality 100` を指定してもロスレスにならない・・・。

ImageMagick をあきらめて、libavif の `avifenc.exe` を試してみることにします。

- Releases ・ AOMediaCodec/libavif ・ GitHub   
  https://github.com/AOMediaCodec/libavif/releases

最新の v0.9.0 をダウンロードして使いました。

```bash
$ ~/Downloads/libavif/v0.9.0/avifenc.exe --version
Version: 0.9.0 (dav1d [dec]:0.8.2-0-gf06148e, aom [enc/dec]:2.0.2)
libyuv : unavailable

$
```

`avifenc.exe --help` で確認すると .bmp ファイルは直接食べられないみたいなので、.png ファイルを入力ファイルとして指定します。

```bash
$ time avifenc.exe --lossless aaa.png ccc.avif
Successfully loaded: aaa.png
AVIF to be written: (Lossless)
 * Resolution     : 3840x2160
 * Bit Depth      : 8
 * Format         : YUV444
 * Alpha          : Not premultiplied
 * Range          : Full
 * Color Primaries: 1
 * Transfer Char. : 13
 * Matrix Coeffs. : 0
 * ICC Profile    : Absent (0 bytes)
 * XMP Metadata   : Absent (0 bytes)
 * EXIF Metadata  : Absent (0 bytes)
 * Transformations: None
Encoding with AV1 codec 'aom' speed [6], color QP [0 (Lossless) <-> 0 (Lossless)], alpha QP [0 (Lossless) <-> 0 (Lossless)], tileRowsLog2 [0], tileColsLog2 [0], 1 worker thread(s), please wait...
Encoded successfully.
 * Color AV1 total size: 10888940 bytes
 * Alpha AV1 total size: 0 bytes
Wrote AVIF: ccc.avif

real    3m2.572s
user    0m0.000s
sys     0m0.031s
$
$ du -sk aaa.png ccc.avif
9964    aaa.png
10636   ccc.avif
$
$ /c/OnlineSoftware/ImageMagick/compare.exe -metric AE aaa.bmp ccc.avif NULL:
0
$
```

無事にロスレスの AVIF ファイルができましたが、ファイルサイズが PNG より大きい・・・。

ためしに一番遅い `--speed 0` を指定してみる。

```bash
$ time avifenc.exe --lossless --speed 0 aaa.png ccc.avif
Successfully loaded: aaa.png
AVIF to be written: (Lossless)
 * Resolution     : 3840x2160
 * Bit Depth      : 8
 * Format         : YUV444
 * Alpha          : Not premultiplied
 * Range          : Full
 * Color Primaries: 1
 * Transfer Char. : 13
 * Matrix Coeffs. : 0
 * ICC Profile    : Absent (0 bytes)
 * XMP Metadata   : Absent (0 bytes)
 * EXIF Metadata  : Absent (0 bytes)
 * Transformations: None
Encoding with AV1 codec 'aom' speed [0], color QP [0 (Lossless) <-> 0 (Lossless)], alpha QP [0 (Lossless) <-> 0 (Lossless)], tileRowsLog2 [0], tileColsLog2 [0], 1 worker thread(s), please wait...
Encoded successfully.
 * Color AV1 total size: 10884272 bytes
 * Alpha AV1 total size: 0 bytes
Wrote AVIF: ccc.avif

real    10m30.801s
user    0m0.000s
sys     0m0.015s
$
$ du -sk aaa.png ccc.avif
9964    aaa.png
10632   ccc.avif
$
$ compare -metric AE aaa.bmp ccc.avif NULL:
0
$
```

1ファイルの変換に10分もかかったけど、ファイルサイズはほとんど変わらなかった。残念。

## JPEG XL をためしてみる

JPEG 後継の JPEG XL は、その名に反して（？）、ロスレス圧縮もサポートしてます。

- JPEG XL - Wikipedia   
  https://ja.wikipedia.org/wiki/JPEG_XL
- Releases ・ libjxl/libjxl ・ GitHub   
  https://github.com/libjxl/libjxl/releases

とりあえず ImageMagick でロスレス圧縮を指定する方法がわからなかったので、libjxl の `cjxl.exe` を使うことにしました。
最新の v0.6.1 の `jxl-x64-windows-static.zip` をダウンロードして使います。

```bash
$ time cjxl.exe aaa.png ddd.jxl -q 100 -v
JPEG XL encoder v0.6.1 a205468 [AVX2,SSE4,Scalar]
Read 3840x2160 image, 31.1 MP/s
Encoding [Modular, lossless, squirrel], 16 threads.
Compressed to 7085947 bytes (6.834 bpp).
3840 x 2160, 0.29 MP/s [0.29, 0.29], 1 reps, 16 threads.
Average butteraugli iters:       0.00
Total layer bits headers          0.000192%       109
Total layer bits TOC              0.005866%      3325
Total layer bits quant tables     0.000002%         1
Total layer bits modularGlobal    0.229026%    129828   [c/i:128.00 | hst:   16223 | ex:       0 | h+c+e: 6837135.182]
Total layer bits modularAcGroup  99.496368%  56401504
Total layer bits modularTree      0.268547%    152231   [c/i:  4.00 | hst:      54 | ex:     893 | h+c+e:   18948.540]
Total image size             56686998   [c/i:132.00 | hst:   16278 | ex:  249837 | h+c+e: 7105027.598]
Allocations: 1132 (max bytes in use: 4.223050E+08)

real    0m29.137s
user    0m0.000s
sys     0m0.031s
$
$ du -sk aaa.png ddd.jxl
9964    aaa.png
6920    ddd.jxl
$
$ compare -metric AE aaa.bmp ddd.jxl NULL:
0
$
```

無事にロスレス圧縮ができました。ファイルサイズが WebP よりさらに小さいですね。ただ、遅いです。

さらに effort を max 指定にしてみます：

```bash
$ time cjxl.exe aaa.png eee.jxl -q 100 -v -e 9
JPEG XL encoder v0.6.1 a205468 [AVX2,SSE4,Scalar]
Read 3840x2160 image, 31.4 MP/s
Encoding [Modular, lossless, tortoise], 16 threads.
Compressed to 6882664 bytes (6.638 bpp).
3840 x 2160, 0.02 MP/s [0.02, 0.02], 1 reps, 16 threads.
Average butteraugli iters:       0.00
Total layer bits headers          0.000198%       109
Total layer bits TOC              0.005995%      3301
Total layer bits quant tables     0.000002%         1
Total layer bits modularGlobal    0.316592%    174318   [c/i:126.00 | hst:   21785 | ex:       0 | h+c+e: 6661939.822]
Total layer bits modularAcGroup  99.085528%  54557192
Total layer bits modularTree      0.591685%    325786   [c/i:  4.00 | hst:     131 | ex:    1751 | h+c+e:   38462.166]
Total image size             55060707   [c/i:130.00 | hst:   21916 | ex:  142402 | h+c+e: 6841052.863]
Allocations: 1132 (max bytes in use: 4.222756E+08)

real    6m5.410s
user    0m0.000s
sys     0m0.015s
local:/i/FF14/images/00_NEW $ du -sk aaa.png eee.jxl
9964    aaa.png
6724    eee.jxl
$
$ compare -metric AE aaa.bmp eee.jxl NULL:
0
$
```

さらに 3% ほどファイルサイズが小さくなりましたが、実行時間が10倍以上に延びてしまいました。コスパ悪い。

ImageMagick でも `-quality 100` 指定でロスレス圧縮になる、との情報をいただいたので、試してみる：   
(thanks [@yoya](https://twitter.com/yoya))   
https://twitter.com/yoya/status/1496499554107404288

```bash
$ time convert aaa.bmp -quality 100 fff.jxl

real    12m45.754s
user    0m0.015s
sys     0m0.000s
$
$ du -sk aaa.bmp *.jxl
24304   aaa.bmp
6920    ddd.jxl
6724    eee.jxl
12548   fff.jxl
$
$ compare -metric AE aaa.bmp fff.jxl NULL:
28697
$
```

すごく時間がかかった上に、微妙にロスレスになってくれなかった。残念。

## BPG をためしてみる


BPG (Better Portable Graphics) 形式というものがあったので、ためしてみます。

- Better Portable Graphics - Wikipedia   
  https://ja.wikipedia.org/wiki/Better_Portable_Graphics
- BPG Image format   
  https://bellard.org/bpg/

ImageMagick は BPG 形式をサポートしていないみたいです。

最新の v0.9.8 の win64 版 `bpg-0.9.8-win64.zip` をダウンロードして使います。

`bpgenc.exe -h` で確認すると .jpg か .png しか食べられないみたいなので、.png ファイルを指定します。

```bash
$ time ~/Downloads/bpg/bpg-0.9.8-win64/bpgenc.exe -o ddd.bpg -c rgb -lossless aaa.png

real    0m2.624s
user    0m0.015s
sys     0m0.000s
$
$ du -sk aaa.png ddd.bpg
9964    aaa.png
11048   ddd.bpg
$
$ ~/Downloads/bpg/bpg-0.9.8-win64/bpgdec.exe -o ddd.bpg.png ddd.bpg
$
$ compare -metric AE aaa.bmp ddd.bpg.png NULL:
0
$
```

無事にロスレス圧縮ができましたが、PNG 形式よりファイルサイズが大きくなってしまいました。

ためしに、compression level を slowest にしてみる：

```bash
$ time ~/Downloads/bpg/bpg-0.9.8-win64/bpgenc.exe -o eee.bpg -c rgb -lossless -m 9 aaa.png

real    0m2.722s
user    0m0.000s
sys     0m0.015s
$
$ du -sk aaa.png eee.bpg ddd.bpg
9964    aaa.png
11048   eee.bpg
11048   ddd.bpg
$
```

結果は変わらず。残念。

## まとめ

実験の結果をまとめると、次の表のようになります：

{% asset_img table20220223a1.png %}

圧縮率は 28% の JPEG-XL が一番いいけど、次点の WebP も 31% と優秀。
そして WebP は実行時間が 7 秒半と短い（JPEG-XL は 29 秒もかかっている）。

最後に、たくさんのファイルでの試験もやってみます。
2020年2月に撮ったスクリーンショット 463 枚（約 11GB）の BMP ファイルを、32 プロセス並列で（`xargs -P 32` を使って）一括変換してみました。

{% asset_img table20220223a2.png %}

WebP の結果が優秀ですね。

あと、JPEG XL 形式に変換したフォルダを画像ビューアー XnView MP で開いてみると、
サムネイル作成がめちゃめちゃ遅いことが判明しました。
かなり不便です。

結論として、WebP を採用することにしました。
