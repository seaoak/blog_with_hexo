---
title: Docker を導入しました
date: 2022-04-25 09:50:45
tags:
---

いまさらながら、はじめて Docker を使ってみました。
先日借りた Linode の VPS (Arch Linux) で Web サーバを動かすためです。
単一プロセスの単一コンテナ運用なので、オーケストレーション（Kubernates とか Docker Swarm とか）は使っていません。

- Docker - ArchWiki   
  https://wiki.archlinux.jp/index.php/Docker
- Arch Linux ? Docker-docs-ja 1.13.RC ドキュメント   
  https://docs.docker.jp/engine/installation/linux/archlinux.html
- Docker run reference | Docker Documentation   
  https://docs.docker.com/engine/reference/run/

## 参考書

以前から雑誌やネット記事で Docker およびコンテナ技術については触れていましたが、
あらためて書籍を読んでお勉強しました。

{% asset_img book_covers_4.jpg "4冊の表紙" %}

- プログラマのためのDocker教科書 第2版 インフラの基礎知識＆コードによる環境構築の自動化 ｜ 翔泳社   
  https://www.shoeisha.co.jp/book/detail/9784798153223
- Docker実践ガイド第2版 - インプレスブックス   
  https://book.impress.co.jp/books/1118101052
- Docker/Kubernetes開発・運用のためのセキュリティ実践ガイド（Compass Booksシリーズ） | マイナビブックス   
  https://book.mynavi.jp/ec/products/detail/id=114099
- イラストでわかる DockerとKubernetes｜技術評論社   
  https://gihyo.jp/book/2020/978-4-297-11837-2

「セキュリティ実践ガイド」は、セキュリティに限らずいろいろ実用的なことが書いてあって、とても参考になりました。

「イラストでわかる DockerとKubernetes」は、Docker の使い方というよりは Docker の仕組みに関する解説書ですね。
いままで雑誌やネット記事で断片的に知っていた内容が整理できて、よかったです。

これらの本で基本的な概念やツールの扱いを把握できたので、
実際の作業の際には Docker 公式ドキュメント（マニュアルとリファレンス）を読むだけで OK でした。

## docker のインストール

Linux (Arch Linux) に Docker をインストールします。
"Docker Desktop for xxx" ではありません（Linux 向けにもベータ版がリリースされていますが）。

パッケージ `docker` を pacman でインストールして、常時稼働するように設定します。

```bash-prompt
$ sudo pacman -S docker
$ sudo systemctl status docker
$ sudo systemctl enable docker
$ sudo systemctl restart docker
$ sudo systemctl status docker
$ sudo docker info
Server:
 Server Version: 20.10.14
 Storage Driver: overlay2
  Backing Filesystem: extfs
  Supports d_type: true
  Native Overlay Diff: false
  userxattr: false
 Logging Driver: json-file
 Cgroup Driver: systemd
 Cgroup Version: 2
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local logentries splunk syslog
 Swarm: inactive
 Runtimes: io.containerd.runc.v2 io.containerd.runtime.v1.linux runc
 Default Runtime: runc
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
 Registry: https://index.docker.io/v1/
 Experimental: false
 Live Restore Enabled: false
（※一部抜粋）
$ sudo docker run hello-world
```

containerd の設定については、必要と思わなかったのでスキップしました。
Docker 公式ドキュメントには `systemctl enable containerd.service` を実行しろと書いてあるけど、やってない。
いまのところ、問題なく使えています。

- Post-installation steps for Linux | Docker Documentation   
  https://docs.docker.com/engine/install/linux-postinstall/#configure-docker-to-start-on-boot

IPv6 の設定もスキップ。なにもしなくてもデフォルトでインターネットとの IPv6 通信ができています。

- Enable IPv6 support | Docker Documentation   
  https://docs.docker.com/config/daemon/ipv6/

bash の補完機能も追加しておいたけど、結局、常に sudo 経由で docker コマンドを叩くので、意味がなかった。

- cli/docker at master ・ docker/cli ・ GitHub   
  https://github.com/docker/cli/blob/master/contrib/completion/bash/docker

## Dockerfile

Dockerfile は、公式リファレンスを読みながらゼロから手書き。

- Dockerfile reference | Docker Documentation   
  https://docs.docker.com/engine/reference/builder/
- Best practices for writing Dockerfiles | Docker Documentation   
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

今回動かすアプリケーション (Caddy) の公式イメージの Dockerfile も参考になりました：

- caddy-docker/Dockerfile at master ・ caddyserver/caddy-docker ・ GitHub   
  https://github.com/caddyserver/caddy-docker/blob/master/2.4/alpine/Dockerfile

レイヤー数をできるだけ少なくするとか、そういった最適化は現時点ではやっていません。わかりやすさ優先。

## Docker Compose

ポートのマッピングとか、volume の割り当てとか、docker コマンドのオプションで毎回指定するのはいろいろよろしくないと思ったので、
Docker Compose を使うことにしました。

まず、Docker Compose V2 をインストールします（せっかく新規にセットアップするのだから V2 にしておいた）。
なお、ホームディレクトリ配下にインストールしたら sudo 時に使えなかったので（あたりまえ）、
`/usr/local/lib/docker` に移動しました。

- Compose V2 | Docker Documentation   
  https://docs.docker.com/compose/cli-command/#install-on-linux
- Releases ・ docker/compose ・ GitHub   
  https://github.com/docker/compose/releases
- Overview of docker-compose CLI | Docker Documentation   
  https://docs.docker.com/compose/reference/

```bash-prompt
$ mkdir -p ~/.docker/cli-plugins
$ cd ~/.docker/cli-plugins
$ curl -OL https://github.com/docker/compose/releases/download/v2.4.1/docker-compose-linux-x86_64
$ chmod a+x docker-compose-linux-x86_64
$ chmod a-w docker-compose-linux-x86_64
$ mv docker-compose-linux-x86_64 docker-compose
$ cd
$ docker compose version
Docker Compose version v2.4.1
$
$ sudo mv .docker /usr/local/lib/docker
$ sudo chown -R root.root /usr/local/lib/docker
$ sudo docker compose version
Docker Compose version v2.4.1
$
```

`docker-compose.yml` の書き方：

- Compose specification | Docker Documentation   
  https://docs.docker.com/compose/compose-file/
- Compose file build reference | Docker Documentation   
  https://docs.docker.com/compose/compose-file/build/
- Compose file deploy reference | Docker Documentation   
  https://docs.docker.com/compose/compose-file/deploy/

Docker 公式ドキュメントとしてはファイル名を `docker-compose.yml` ではなく `compose.yaml` にしたい意向みたいですが、
世の中で広く `docker-compose.yml` という名前が使われていますし、いまさらファイル名を変えるのはわかりにくいだけだと思ったので、
今回は `docker-compose.yml` にしました。
（公式ドキュメントでもあちこちで `docker-compose.yml` と書いてある）

## ログをどうするか？

コンテナ内で稼働させるアプリケーションのログの扱いです。

Docker の stdout に吐かせるか、コンテナにマウントさせたディレクトリにログファイルを吐かせるか。

パフォーマンス的には、コンテナにマウントさせた volume にアプリケーションプロセスが
直接ログファイルを書くのが良さそうな気がします。
ただし、ハッキングされてアプリケーションプロセスが乗っ取られた場合に、
ログファイルを改ざんされてしまうリスクがあります。

- Docker ロギングのベストプラクティス | Datadog   
  https://www.datadoghq.com/ja/blog/docker-logging/
- Docker コンテナにおけるログローテーションの設定 | Boatswainブログ   
  https://blog.boatswain.io/ja/post/docker-container-log-rotation/

fluentd が使えるかも？ と思いましたが、アプリケーションプロセスがひとつしかないのに大げさな気がしました。

- fluentdでdockerコンテナのログをファイルごとに出し分けてみたお話 - Qiita   
  https://qiita.com/kito_engineer/items/b3f5f15c60de504a13a3

結局、アプリケーションプロセスのログは標準出力／標準エラー出力に全部吐かせて、
Docker のロギングドライバでなんとかすることにしました。

ここで、今回のアプリケーション (Caddy) はもともと JSON 形式でログを吐いてくれて、タイムスタンプも含まれています。
Docker でログドライバとして `json-file` を指定すると、

- ネストした JSON (JSON in JSON) になってしまう
- タイムスタンプが二重に記録される

というムダが生じます。
とはいえ、前者については jq コマンドの出力をパイプで繋いでもう一度 jq コマンドに渡せば解決しますし、
後者に関しては、まぁ、無視できるオーバーヘッドかと思われます。

一方、Docker のログドライバとして `local` を指定すると、

- アプリケーションプロセスの標準出力と標準エラー出力が区別できない
- Docker 独自形式なので生のログファイルをコピーしても読めない

という問題があります。

今回は、`json-file` を使うことにしました。

ログのバッファリングについては、実際にところ問題になるとは思われなかったので、デフォルトのままとしました。

- JSON File logging driver | Docker Documentation   
  https://docs.docker.com/config/containers/logging/json-file/
- Local File logging driver | Docker Documentation   
  https://docs.docker.com/config/containers/logging/local/
- Configure logging drivers | Docker Documentation   
  https://docs.docker.com/config/containers/logging/configure/
  > The non-blocking message delivery mode prevents applications from blocking due to logging back pressure.
  > Applications are likely to fail in unexpected ways when STDERR or STDOUT streams block.

```yaml
    logging:
      driver: json-file
      options:
        max-size: 20m
        max-file: 999
```

ちなみに、コンテナを起動したら、そのログファイルの実体（絶対パス）を `docker inspect` コマンドで確認できます。

```bash-prompt
$ sudo docker inspect $CONTAINER_NAME 2>/dev/null | jq -e -r '.[].LogPath // empty'
```

- Dockerコンテナのデフォルトログ出力設定 - galife   
  https://garafu.blogspot.com/2019/11/config-docker-logs.html

今回の環境では、`/var/lib/docker/containers/コンテナID/コンテナID-json.log` でした。

なお、ログローテーションした結果、どう変わるのかは、まだわかってません：

- ログファイルの実体（パス）は変わるのか？
- ローテートされた過去のログファイルも `docker inspect` コマンドで確認できるのか？
- ローテートされた過去のログファイルの内容も `docker logs` コマンドで確認できるのか？

おまけ：

コンテナのログファイルは、コンテナを削除 (`docker container rm`) すると削除されてしまいます。
残しておきたいなら、どこかに待避しておく必要があります。
このとき、単にホスト上の別のディレクトリに待避したいのなら（同一パーティーション内であれば）、
「コピーする」よりも「ハードリンクを作る」ほうが便利です。
ログファイルの中身に一切触らないので、一瞬で終わります。
Docker がオリジナルのパスを削除 (unlink) しても、新しく作ったハードリンクがあるので、ファイルは消えません。
ハードリンクを作るには、`ln` コマンドを実行します（シンボリックリンクを作るオプション `-s` は付けない）。

```bash-prompt
$ sudo docker inspect $CONTAINER_NAME | jq -r '.[].LogPath' | xargs -r -t sudo ln -f -t ./log-archive
```

ちなみに、コンテナ実行中にログファイルのハードリンクを作ることも可能です。
オリジナルのログファイルのディレクトリには root 権限がないとアクセスできないので、
適当なユーザのホームディレクトリ配下にハードリンクを作っておくと便利だったりします。
ただし、このとき、新しく作ったハードリンクに対して `chown` したり、`chmod u-w` 相当のことをしたりするのは、
Docker の挙動に影響が生じる可能性があるので、やめておいたほうが安全だと思われます（下図スクリーンショット参照）。
これは、ハードリンクの属性を変えると、オリジナルのログファイルの属性も変わってしまうためです
（ファイルの属性情報はディレクトリエントリではなく inode にあるのです）。
`chmod a+r` だけならたぶん大丈夫。
もちろん、ログファイルに誰でもアクセスできてしまってはセキュリティ上よろしくないので、
ハードリンクを作ったディレクトリのパーミッションを `700` とかにしておくべきですね。

{% asset_img SS20220423a_Docker_manual_loging_driver_warning.png "Docker 公式ドキュメントの注意書き（「ログファイルには触るな」と書いてある）" %}

## ディスクへの書き込みサイズを制限する

Docker コンテナを稼働させるにあたり、ディスクの使用量制限をかけたい。

コンテナ内のプロセスがハッキングされたときに、コンテナにマウントさせた volume に大量の書き込みをされると、
ホストの disk full を招く恐れがあります。これを防ぎたい。

コンテナからの書き込みは、ホスト上では特定のユーザによる書き込みに見える（ように Docker を設定する）ので、
ユーザ単位で quota がかけられれば OK かな、と考えました。ちょっと調べてみる：

- ext4のDisk Quotaあれこれ - Qiita   
  https://qiita.com/takeoverjp/items/0f4966bbead0b5e3bf4f

上記の記事では ex4 のディスクイメージファイルを作って、それをマウントして操作しています。
これができるなら、わざわざ quota を使わなくても書き込みサイズの制限が可能になります。

というわけで、64MB のイメージファイルを作って試してみました。

```bash-prompt
$ truncate -s 64M volume_caddy_ext4.img
$ mkfs.ext4 ./volume_caddy_ext4.img
$ dumpe2fs ./volume_caddy_ext4.img
$ mkdir mnt
$ sudo mount ./volume_caddy_ext4.img ./mnt
$ df ./mnt
Filesystem     1K-blocks  Used Available Use% Mounted on
/dev/loop0         56037    15     51436   1% /home/caddy/mnt
$
$ sudo mkdir ./mnt/caddy
$ sudo chown -R caddy:caddy ./mnt/caddy
```

実際に書き込みテストをしてみると、小さいサイズ (3MB) は問題なく書き込めて、
イメージファイルのサイズを超える書き込み (100MB) はちゃんとエラーになります。

```bash-prompt
$ dd if=/dev/zero of=./mnt/caddy/z bs=1K count=3K
3072+0 records in
3072+0 records out
3145728 bytes (3.1 MB, 3.0 MiB) copied, 0.00651232 s, 483 MB/s
$
$ dd if=/dev/zero of=./mnt/caddy/z bs=1K count=100K
dd: error writing './mnt/caddy/z': No space left on device
51436+0 records in
51435+0 records out
52669440 bytes (53 MB, 50 MiB) copied, 0.133398 s, 395 MB/s
$
$ df ./mnt
Filesystem     1K-blocks  Used Available Use% Mounted on
/dev/loop0         56037 51451         0 100% /home/caddy/mnt
$
```

今回は、上記のように固定サイズのディスクイメージファイルをホスト上でマウントして、
その中のディレクトリを Docker コンテナに volume としてマウントさせる、
という方針にしました。

## アプリケーションデータの扱い

- Where and how to persist application data - Docker development best practices | Docker Documentation   
  https://docs.docker.com/develop/dev-best-practices/#where-and-how-to-persist-application-data
- Use volumes | Docker Documentation   
  https://docs.docker.com/storage/volumes/
- Use bind mounts | Docker Documentation   
  https://docs.docker.com/storage/bind-mounts/
- Dockerでファイルをbind mountしたら同期されなかった話   
  https://zenn.dev/techno_tanoc/articles/449d580e18d2f4   
  ⇒ ファイル単体を指定しての bind mount は inode で束縛されているので、テキストエディタとかで編集するのは危険らしい

アプリケーションデータの扱いは、いろいろ試行錯誤した結果、以下の方針にしました：

- アプリケーションデータを置くディレクトリは、すべてコンテナの volume として与える。
  コンテナイメージ内には一切置かない。
- アプリケーションが実行時に生成するファイル／ディレクトリは、
  ホスト上のディスクイメージファイルをホスト上でマウントしたディレクトリを「読み書き可能 volume」としてコンテナにマウントする。
- アプリケーションが読み取るファイル／ディレクトリは、ホスト上のディレクトリを「read-only volume」としてコンテナにマウントして参照させる。

ここでのポイントは、コンテナ内のアプリケーションプロセスのユーザ ID (UID) と、
ホスト上のファイル／ディレクトリの所有者の UID を一致させておくことです。
「ユーザ名」自体は異なっていても問題ありません（いろいろ混乱しそうな気もしますが）。
コンテナ内のアプリケーションプロセスの UID を指定するためには、
Dockerfile でイメージをビルドするときに ARG や環境変数で指定するか、あるいは、
`docker-compose.yml` の中で `user` プロパティで指定するか、あるいは、
コンテナ起動時に docker コマンドのコマンドライン引数 `-u` (`--user`) で指定するか、
いずれかの方法をとります。

【2022/Apr/26 追記】   
Twitter で知ったのですが、`docker-compose.yml` の `volumes:` のセクションで "short syntax" を使うと罠があります。
bind 元となるホスト側のパスが存在しない場合、Docker が勝手に自動生成してくれちゃうのです。
"long syntax" を使えば（`create_host_path: true` を指定しなければ）、コンテナ生成時にエラーになってくれます。

- docker-compose の bind mount を1行で書くな   
  https://zenn.dev/sarisia/articles/0c1db052d09921

修正前の `docker-compose.yml` ：

```yaml
    volumes:
      - ./mnt/caddy/config:${XDG_CONFIG_HOME:?must be set}
      - ./mnt/caddy/env:${CADDY_ENV_DIR:?must be set}:ro
```

修正後の `docker-compose.yml` ：

```yaml
    volumes:
      - type: bind
        source: ./mnt/caddy/config
        target: ${XDG_CONFIG_HOME:?must be set}
      - type: bind
        source: ./mnt/caddy/env
        target: ${CADDY_ENV_DIR:?must be set}
        read_only: true
```

修正後は `docker compose up` コマンドがちゃんとエラーになってくれました：

```bash-prompt
$ sudo -E docker compose up -d
Container caddy  Creating
Error response from daemon: invalid mount config for type "bind": bind source path does not exist: /home/caddy/mnt/caddy/config
$
```

Docker 公式ドキュメントにも、**よく読めば**注意書きがあります。
"short syntax" のこのおせっかいな挙動は、過去の docker-compose との互換性を保つためとのこと。

- Compose specification | Docker Documentation   
  https://docs.docker.com/compose/compose-file/#long-syntax-4
  > `create_host_path:` create a directory at the source path on host if there is nothing present.
  > Do nothing if there is something present at the path.
  > This is automatically implied by short syntax for backward compatibility with docker-compose legacy.

## CPU やメモリに制約をかける

コンテナ内のアプリケーションプロセスが高負荷になったとき、ホストの CPU やメモリを使い果たされてしまうと困ります。
とくに、アプリケーションプロセスがハッキングされてしまったときのことを考えると、コンテナの CPU 優先度を下げておきたいです。

nice コマンドみたいに高負荷時にコンテナの CPU 優先度を下げるには、docker コマンドの `--cpu-shares` オプションを使うらしい。
デフォルト値が `1024` なので、たとえば `512` とかを指定すればいいのかな？

メモリスワップは嫌いなので無効化しておきます。
スワップが発動するのなんてアプリケーションプロセスがメモリリークしていたときとかハッキングされたときくらいなので、すなおに落ちてくれたほうがマシです。
あと、ついでに PID の上限数も適当な値に設定しておきます（ハッキングされたときにホストのカーネルの PID 空間を使い果たされてしまうのを防ぐため）。
すべて `docker-compose.yml` の `services:` セクションの中に書きます。

- メモリ、CPU、GPU に対する実行時オプション ? Docker-docs-ja 19.03 ドキュメント   
  https://docs.docker.jp/v19.03/config/container/resource_constraints.html
  > --memory と --memory-swap に同じ値を設定した場合、コンテナがスワップを利用しないようになります。

```yaml
    # soft limit CPU "50%"
    cpu_shares: 512

    # hard limit memory 1GB
    deploy:
      resources:
        limits:
          memory: 1gb
          pids: 99

    # no memory swap
    memswap_limit: 1gb
```

## コンテナのファイルシステムを read-only にしておく

オペミスでコンテナイメージ内にファイルを作ってしまってコンテナ再ビルドでロストしてしまう問題の予防と、ハッキング対策です。
万一、コンテナ内に侵入されたときに、ホストのファイルシステムが disk-full にされるリスクも軽減できるハズ。
なお、コンテナにマウントさせた volume は、変わらず読み書きできます。

`docker-compose.yml` の中で `services:` セクションに1行書くだけです。

```yaml
    read_only: true
```

## コンテナに与える Capabilities を制限する

- Capabilities | dockerlabs   
  https://dockerlabs.collabnix.com/advanced/security/capabilities/
- Compose specification | Docker Documentation   
  https://docs.docker.com/compose/compose-file/#cap_add

コンテナに与える特権（一般的に root ユーザのみが可能な操作）を必要最小限に制限します。
万一、コンテナにハッキングされてコンテナ内で root 権限を奪われたときの被害を軽減できます。
（コンテナからの break-out とは別の話です）

Caddy を実行するだけなら `NET_BIND_SERVICE` 以外の capability は不要なので、
いったんすべての capability を捨てて、`NET_BIND_SERVICE` のみ個別に許可するようにします。

具体的には、`docker-compose.yml` の `services:` セクションの中に以下の記述を追加します：

```yaml
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
```

ちなみに、コンテナ内のアプリケーションプロセスに `NET_BIND_SERVICE` capability を付与したい場合、
もちろんコンテナ内の root 権限でプロセスを実行すれば自動的に付与されます。
しかし、セキュリティをより強固にするため、root 権限ではなく一般ユーザ権限でアプリケーションプロセスを実行したい、というケースもあるかと思います。

こんなときには、実行ファイルへの capability の付与、という仕組みを使うと、簡単にアプリケーションプロセスに capability を付与できます。

具体的には、アプリケーションの実行ファイルに対して `setcap` コマンドを実行するだけです。
`setcap` コマンドの実行には root 権限が必要なので、Dockerfile の中で `USER` 命令を使う前に実行します。
`setcap` コマンドがインストールされていない場合は `libcap` パッケージをインストールします。

```Dockerfile
RUN type setcap >/dev/null 2>&1 || pacman -S libcap
RUN setcap CAP_NET_BIND_SERVICE+eip ./caddy
```

これをやっておくと、普通に一般ユーザ権限で実行ファイルを実行すれば（`sudo` とか無しで）、
常に capability が付与された状態でプロセスが起動します。

実行ファイルに付与されている capability は、`getcap` コマンドで確認できます。

```bash-prompt
$ sudo docker exec -it $CONTAINER_NAME /bin/bash
[caddy@adbe070c2eac ~]$ getcap ./caddy
./caddy cap_net_bind_service=eip
[caddy@adbe070c2eac ~]$
```

## Docker イメージを再ビルドしてくれない

`Dockerfile` や `docker-compose.yml` や環境変数を変更しても、起動コマンド `docker compose up` で再ビルドされず、しばし悩む。
公式ドキュメントを読み直した結果、`--build` オプションを追加すれば良いとわかった。

- docker-compose up | Docker Documentation   
  https://docs.docker.com/compose/reference/up/

`--build` オプションを指定すると再ビルドを実行してくれますが、
`Dockerfile` や `docker-compose.yml` の設定に変更がなければ（同じ設定でビルドした既存のイメージがあれば）、
すべてのレイヤーが `CACHED` となって数秒で終わります。
新規のイメージが作られることもなく、イメージ名やハッシュ値もそのまま変わりません。
（タグ `latest` は再ビルドの結果のイメージに付け替えられます）

## `docker compose up` でビルドされたイメージに名前を付ける

デフォルトでは、`docker compose` でビルドしたイメージの名前は「プロジェクト名_コンテナ名」になる模様。
「プロジェクト名」は、`docker-compose.yml` で明示的に指定しなければ、カレントディレクトリ名になる模様。
また、タグ `latest` が自動的に付与されます。

条件を変えて再ビルドすると、その結果のイメージはデフォルトの名前とタグ (`latest`) になり、
古いイメージは「タグなし」になります（イメージ名は同じ）。

「タグなし」のイメージがあるのはいろいろよろしくないので、
とりあえず、`docker compose up` の直後に `docker tag` コマンドを実行して、
`latest` タグのイメージに対して明示的にタグを打つようにしました。

- Compose file build reference | Docker Documentation   
  https://docs.docker.com/compose/compose-file/build/#labels
- docker tag | Docker Documentation   
  https://docs.docker.com/engine/reference/commandline/tag/

シェルスクリプトの例：

```bash
IMAGE_NAME=$(sudo docker inspect $CONTAINER_NAME 2>/dev/null | jq -e -r '.[0].Config.Image // empty')
IMAGE_TAG=run$(date '+%Y%m%d_%H%M%S')_v${CADDY_VERSION}
sudo docker image tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${IMAGE_TAG}
sudo docker image ls -a
```

## コンテナの自動スタート＆リスタート

サーバ（ホスト）が起動したときに自動でコンテナも起動されるようにします。
アプリケーションプロセスが落ちたとき or コンテナが落ちたときにも、自動的に再スタートしてほしい。

- コンテナーの自動起動 | Docker ドキュメント   
  https://matsuand.github.io/docs.docker.jp.onthefly/config/containers/start-containers-automatically/
- Compose specification | Docker Documentation   
  https://docs.docker.com/compose/compose-file/#restart

ためしに、Docker コンテナの restart policy に `unless-stopped` を設定してみる（`docker-compose.yml` の `services:` セクションに以下の行を追加）：

```yaml
    restart: unless-stopped
```

これで、サーバの起動時に自動的に Docker コンテナが起動されるようになりました。

しかし、ホスト上でディスクイメージをマウントしたりする前処理が走らないため、caddy が正しく動作しません。

あきらめて、systemd を使って制御するようにしました。
（`docker-compose.yml` での restart policy はデフォルト値 `"no"` に戻しておきます）

- dockerのコンテナの自動起動をsystemdにて行う際の注意点について | めもたんす   
  https://www.memotansu.jp/docker/563/
- systemdを用いたプログラムの自動起動 - Qiita   
  https://qiita.com/tkato/items/6a227e7c2c2bde19521c
- 自作したシェルスクリプトを Linux の systemd サービスとして起動する方法 | ゲンゾウ用ポストイット   
  https://genzouw.com/entry/2021/07/05/154156/2701/
- Ubuntu Manpage: systemd.service - Service unit configuration   
  https://manpages.ubuntu.com/manpages/xenial/en/man5/systemd.service.5.html

上記の参考記事には「`docker start` コマンドに `-a` オプションを指定する」というアドバイスが載っていますが、
要は `ExecStart` で指定したプログラムが exit しなければ良いという話です。いわゆる daemon mode というやつですね。
docker compose を使う場合は、`docker compose up -d` で起動＆デタッチしておいて、
起動用シェルスクリプトの最後で `docker wait $CONTAINER_NAME` を実行してあげれば OK です。
ここで、`docker compose up` でデタッチしなければ exit しないので問題ないのでは？ となりそうですが、
そうすると Docker コンテナのコンソール出力がすべて systemd (journald) に取り込まれてしまいます。
今回は、コンテナのコンソール出力が `json-file` ログドライバでコンテナのログファイルに記録されているので、
ログが二重に保存されることになってしまいます。
`docker compose up -d` でデタッチすればアプリケーションプロセスの stdout/stderr は journald には吐かれなくなるので、
この問題を回避できます。

さて、テキストファイル `/etc/systemd/system/caddy.service` を新規作成して、`sudo systemctl daemon-reload` を実行。
これで、`sudo systemctl start caddy` とか `sudo systemctl stop caddy` とかができるようになりました。
シェルスクリプトのログは `sudo journalctl -u caddy` で確認できます（行の先頭に長い文字列が付くのが邪魔ですが）。
最後に、`sudo systemctl enable caddy` を実行して、サーバ起動時に自動的にコンテナが起動されるようにしておきます。

ためしに `sudo docker kill caddy` でコンテナを落としてみると、systemd が自動的にリスタートしてくれた。OK。

書いた `caddy.service` ファイルの中身は以下の通りです：

```ini
[Unit]
Description=Caddy web server on docker
Requires=docker.service
After=docker.service

[Service]
Type=simple
User=root
Group=root
Restart=on-failure
ExecStart=/home/caddy/run_caddy.sh daemon
ExecStop=/home/caddy/run_caddy.sh stop
SyslogIdentifier=Caddy
#StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
```

なお、Caddy 稼働中にシェルスクリプトを書き替えると、コンテナが停止したときに挙動がおかしくなることがあります。
これは、シェルスクリプトの最後で `sudo docker wait $CONTAINER_NAME` を実行しているけど、
シェルスクリプトのファイル自体はオープンしたままになっていて、
コンテナが停止してシェルスクリプトに制御が戻ったときにファイルを後続部分を読み直して、
書き換わった後のデータを読んで、それを処理しようとしてしまって、動作がおかしくなるのです。
この問題は、最後の行を `exec` コマンドで実行するようにすれば回避できます。わかっていれば簡単な話。

```bash
exec sudo docker wait $CONTAINER_NAME
```

## おまけ：参考になりそうなドキュメント

- Best practices for writing Dockerfiles | Docker Documentation   
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Docker security | Docker Documentation   
  https://docs.docker.com/engine/security/
