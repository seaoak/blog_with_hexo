---
title: Windows 10 で WSL2 と Docker をセットアップ
date: 2022-02-03 12:35:43
tags:
  - Docker
  - WSL2
---

[雑誌「Software Design 2021年12月号」](https://gihyo.jp/magazine/SD/archive/2021/202112)の Docker 特集記事を読んで、Docker を試してみたくなりました。
自宅の Windows 10 の PC に Docker 環境をインストールして遊んでみることに。
せっかくなので、Docker のバックエンドには、Hyper-V ではなくて WSL2 (Windows Subsystem for Linux 2) を選びたいところ。
最終的には、Docker Desktop for Windows はあきらめて、Rancher Desktop 1.0.0 を使うことにしました。

{% asset_img book_SoftwareDesign2021Dec.jpg %}

## まえがき

Docker も WSL2 も以前から興味があって、いろいろ調べてはいたのですが、実際に使ったことはありませんでした。
WSL2 は「Windows 上で bash とか使えて便利！」とか聞きますが、わたしはもともと [Git for Windows](https://gitforwindows.org) という MSYS ベースの環境を入れてて、
bash とか perl とかふつうに使えていたので、特に必要性は感じていなかったのです。
本題には関係ないんですが、[FFmpeg](https://www.ffmpeg.org) とか [ImageMagick](https://imagemagick.org) とかをシェルスクリプトで走らせるの、すごく便利ですよね。
複数ファイルのバッチ処理も `xargs -P` で並列化するだけで簡単にマルチコアを有効活用できちゃいます。

Docker は、プライベートの独自ドメインを運用している VPS サーバで使いたいとは思っていて、本を買ったけど読んでなかったりして、
次にサーバを乗り替えるタイミングで導入するつもりでした。
実は、いま借りている VPS はカーネルが古くて Docker 使えないのです。
そこで、手元の Windows PC で Docker 動かせばいろいろ遊べるのでは？ というお話になるわけです。

まず、そもそも Windows 上で Docker を動かすってどういう意味？ というところから調べてみる：

- Windows 10 Homeでも使えて、インストールも超簡単な「Docker Desktop for Windows」登場：Windows 10 The Latest（1/2 ページ） - ＠IT   
  https://atmarkit.itmedia.co.jp/ait/articles/2011/20/news015.html
- Windows上でDockerコンテナを動かす！ その歴史 - クリエーションライン株式会社   
  https://www.creationline.com/lab/42842
- WindowsでDocker環境を試してみる - Qiita   
  https://qiita.com/fkooo/items/d2fddef9091b906675ca
- Windows環境のDockerとWSLの活用方法・手順を解説 | アンドエンジニア   
  https://and-engineer.com/articles/YcQ_4RAAACQAn1yE
- Docker Desktopに依存しない、WindowsでのDocker環境 - Qiita   
  https://qiita.com/ohtsuka1317/items/617a865b8a9d4fb67989

とりあえず、WSL2 をバックエンドにして Docker を動かすのが、一番オーバーヘッドが少なそう。
WSL2 に入れたディストリビューション上で Docker を動かしてもいいのですが、
やっぱり Windows のコマンドライン上で `docker` コマンドが使えたほうが便利そうな気がする。
[Docker Desktop for Windows の新しいライセンス形態について話題になっています](https://www.publickey1.jp/blog/21/docker_desktop250100011.html)が、とりあえず個人的な利用だから OK でしょう。

というわけで、つぎに WSL2 について調べてみる：

- WSL 1 と WSL 2 の比較 | Microsoft Docs   
  https://docs.microsoft.com/ja-jp/windows/wsl/compare-versions
- WSL のインストール | Microsoft Docs   
  https://docs.microsoft.com/ja-jp/windows/wsl/install
- 以前のバージョンの WSL の手動インストール手順 | Microsoft Docs   
  https://docs.microsoft.com/ja-jp/windows/wsl/install-manual
- WSL での詳細設定の構成 | Microsoft Docs   
  https://docs.microsoft.com/ja-jp/windows/wsl/wsl-config

だいたい理解できた。

## 実際の作業

環境：

    OS: Windows 10 Pro 64bit 21H2 (build 19044)
    CPU: AMD Ryzen Threadripper 2950X (16core/32thread, 3.5GHz)
    MEM: 32GB
    
    Hyper-V 利用中（いろいろ実験用の Windows 10 をゲストとして動かしている）
    Windows Defender 以外のセキュリティソフトは無し

まず、Windows の機能を有効化します。
（Windows のコマンドラインで `wsl --install` とやればよろしくやってくれるような話もありますが、今回は手動で有効化しました）

{% asset_img SS_Windows_functions_modified.png %}

上図で赤線を引いてある「Linux 用 Windows サブシステム」と「仮想マシン プラットフォーム」にチェックマークを付けます。
なお、この設定ウインドウは、   
    「設定」⇒「アプリ」⇒「オプション機能」⇒「Windows のその他の機能」   
で開けます。

で、本来はここで WSL2 にてきとうなディストリビューション（Ubuntu-20.04 とか）を入れるのでしょうが、
Docker 環境以外に余計なモノを入れたくなかったので、スキップ。

いきなり Docker Desktop for Windows をインストールします。
Docker の公式サイトからインストーラーをダウンロードして実行。

- Install Docker Desktop on Windows | Docker Documentation   
  https://docs.docker.com/desktop/windows/install/
- Docker for Windows を始めよう ? Docker-docs-ja 19.03 ドキュメント   
  https://docs.docker.jp/docker-for-windows/

{% asset_img SS_Docker_installer.png %}

バージョンは 4.4.4 (73704) でした。
今回は Docker のバックエンドを WSL2 にしたいので、「`Install required Windows components for WSL2`」のチェックボックスを ON にしておきます。
なお、ダウンローダーの .exe ファイルをダブルクリックしても起動せず、右クリックメニューから「管理者として実行」しないとダメでした。

インストーラーは無事終了。

デスクトップに作られたアイコンをダブルクリックして起動してみると、エラーダイアログが出てしまいました。
なにやら内部エラーで例外をスローしている模様。
「`Failed to deploy distro docker-desktop to`」とか言ってますが、よくわからない。

ググってみると、「Docker Desktop for Windows の WSL2 バックエンドは Hyper-V とは共存できない」みたいな話が出てきます。
Docker Desktop for Windows の Dashboard 画面は開いたので、**設定画面で WSL2 バックエンドを無効化**してみると、エラーにはならなくなりました。
でも、これでは当初のもくろみから外れてしまいます・・・。

Windows のコマンドラインで `wsl -l -v` を実行すると、`docker-desktop` と `docker-desktop-data` が確認できました。

しかし、タスクトレイのアイコンをクリックしても右クリックしても反応しなかったり、すごく遅れて右クリックメニューが開いたんだけど項目がクリックできなかったり、**すごく不安定**。

もしかして WSL2 がちゃんとセットアップできていないのかも？ と疑って、てきとうなディストリビューションを入れてみることに。

Windows のコマンドラインで `wsl --install -d Ubuntu-20.04` と実行すると、あっさり成功。
しかし、`wsl -l -v` で確認すると、WSL のバージョンが `2` ではなく `1` になってしまっていました。謎。

よくわからないので、いったん Docker Desktop for Windows をアンインストール。
WSL2 に入れた Ubuntu-20.04 もアンインストール（`wsl --unregister Ubuntu-20.04`）。

もう一度、Docker Desktop for Windows をインストール。しかし、症状は変わらず。

WSL2 にももう一度 Ubuntu-20.04 を入れようとしたら、開いたコンソールウインドウにエラーメッセージが出てインストールできず。
エラーコード `0x8007000e` との表示。
ググってみると、これは WSL2 がメモリ不足だと言っているらしく、WSL2 の設定ファイル `.wslconfig` を作ってあげれば回避できるらしい。

- Error: 0x8007000e Not enough memory resources are available to complete this operation. · Issue #5240 · microsoft/WSL · GitHub   
  https://github.com/microsoft/WSL/issues/5240#issuecomment-631914931
- WSL での詳細設定の構成 | Microsoft Docs   
  https://docs.microsoft.com/ja-jp/windows/wsl/wsl-config


Windows のユーザープロファイルのフォルダ（`C:\Users\ユーザ名` あるいは `%UserProfile%`）に、以下のような内容のテキストファイル `.wslconfig` を置きました。
（いちおう念のため改行コードは CR+LF にしておきました）

```
[wsl2]
memory=4GB
processors=16
swap=8GB
```

無事に Ubunto-20.04 のインストールができるようになりました。

しかし、Docker Desktop for Windows の不安定さは変わらず。

ひとまずあきらめて、Docker Desktop for Windows をアンインストール。

代わりに、最近リリースされたばかりの Rancher Desktop 1.0.0 を試してみることにしました。

- 「Rancher Desktop 1.0」正式リリース。Win/M1 Mac/Intel MacにコンテナとKuberntes環境を簡単に構築、設定できるElectronベースのアプリ － Publickey   
  https://www.publickey1.jp/blog/22/rancher_desktop_10winm1_macintel_mackubernteselectron.html
- Docker DesktopからRancher Desktopに乗り換えてみた - knqyf263's blog   
  https://knqyf263.hatenablog.com/entry/2022/02/01/225546
- まるでDocker Desktop！！Rancher Desktopの登場です - Qiita   
  https://qiita.com/moritalous/items/14d4099023981dcf4fd2
- Rancher Desktop   
  https://rancherdesktop.io/
- FAQ | Rancher Desktop Docs   
  https://docs.rancherdesktop.io/faq

公式サイトからインストーラーをダウンロードして、実行。問題なくインストールできました。
WSL2 にちゃんと入っているようです。

```cmd
> wsl -l -v
  NAME                    STATE           VERSION
* Ubuntu-20.04_dev        Stopped         2
  rancher-desktop         Running         2
  rancher-desktop-data    Stopped         2
>
```

Windows のコマンドラインで `docker` コマンドが使えるようになりました。

デフォルトでは Kubernates のコンテナが動いているらしいのですが、使う予定もないですし、Rancher Desktop の公式 FAQ にしたがって停止させることにしました。

```cmd
> kubectl config use-context rancher-desktop
> kubectl delete node lima-rancher-desktop
```

ここで、削除するノード名（？）が違っているらしく、`delete` がエラーに。
`kubectl get nodes` コマンドでノード名を確認して、再度実行。無事成功。

```cmd
> kubectl get nodes
> kubectl delete node seaoak-pc
> kubectl get nodes
```

`docker` コマンドで `hello-world` コンテナをダウンロードして実行することもできました。OK。

最後に、Rancher Desktop を含めて WSL2 にインストールされているディストリビューションを、Cドライブから別のドライブに移動させます。
C ドライブはすでに容量不足ですし、Docker イメージとか大きなモノは別のドライブに入れるようにしたいのです。

- WSL2のLinuxおよびDockerイメージ格納先を任意のディレクトリに移動する - SIS Lab   
  https://www.meganii.com/blog/2021/07/11/move-the-destination-of-wsl2-linux-and-docker-image-container-to-another-directory/
- WSL2 Dockerのイメージ・コンテナの格納先を変更したい (WSL2のvhdxファイルを移動させたい) - Qiita   
  https://qiita.com/neko_the_shadow/items/ae87b2480345152bc3cb
- 標準機能だけでWSLを好きな場所にインストールする - Qiita   
  https://qiita.com/yamada6667/items/9e73193b0167cba2351d

Windows のコマンドラインで、一度 tar ファイルに export して、それを import すれば OK です。簡単！

```cmd
> E:
> cd \
> mkdir WSL
> cd WSL
> mkdir images
> mkdir archives
> cd archives
> wsl --export rancher-desktop rancher-desktop_20220202a.tar
> wsl --export rancher-desktop-data rancher-desktop-data_20220202a.tar
> wsl --unregister rancher-desktop-data
> wsl --unregister rancher-desktop
> wsl -l -v
> wsl --import rancher-desktop E:\WSL\images\rancher-desktop .\rancher-desktop_20220202a.tar --version 2
> wsl -l -v
> wsl --import rancher-desktop-data E:\WSL\images\rancher-desktop-data .\rancher-desktop-data_20220202a.tar --version 2
> wsl -l -v
```

なお、import した tar ファイルは、削除してしまって問題ありません。

これで、今後、Docker イメージをたくさん作っても安心です。

以上、Windows 10 上での WSL2 と Docker のセットアップでした。
