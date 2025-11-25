# 阿美語萌典 2024 開發新版

阿美語萌典團隊的 [hackfoldr 傳送門](https://beta.hackfoldr.org/11BRa7Ftnni8Q1NRdjwS378BgBz832UY4uIr-d0J0YpM)。

舊版程式碼請至 [https://github.com/g0v/amis-moedict](https://github.com/g0v/amis-moedict) 。

## About 'Amis moedict

’Amis/Pangcah Dictionary, an online ’Amis to Chinese / English / French dictionary, was established with the power of citizens to preserve the once considered soon-to-disappear indigenous language.

In Taiwan, there are 16 different indigenous nations. Though their languages never developed into writing system, detailed records have been made with the efforts of missionaries and cultural heritage inheritors.

The ’Amis/Pangcah Dictionary is the first example of an digitized, online indigenous language dictionary. We hope that others can develop their own online dictionaries, too.

## Pre-Requirement 環境需求

* homebrew (recommend) or MacPorts
* [Orb Stack](https://orbstack.dev/) (recommend), [Docker Desktop](https://www.docker.com/products/docker-desktop/) or Docker CLI
* Docker-compose
* docker-sync
* puma-dev
* mysql-client

### Install homebrew 安裝 homebrew

Checkout https://brew.sh/zh-tw/

    ```shell
    $ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```

### Install Orb Stack

Open [Orb Stack](https://orbstack.dev/download) to download desktop application.

### puma-dev set local DNS for dev

Install Puma-dev Server (https + http):

    ```shell
    $ brew install puma/puma/puma-dev
    $ sudo puma-dev -setup
    $ puma-dev -install
    ```

After install puma-dev

    ```shell
    $ cd ~/.puma-dev
    $ echo 8889 > ~/.puma-dev/new-amis.moedict
    ```

Import Cert to Chrome

    ```shell script
    $ security add-trusted-cert -k login.keychain-db ~/Library/Application\ Support/io.puma.dev/cert.pem
    ```

Import Cert to Firefox

    - open about:preferences#privacy > 檢視憑證
    - 憑證機構 > 匯入 `~/Library/Application\ Support/io.puma.dev/cert.pem`

If local browser shows https cert expired, then

    ```shell script
    $ puma-dev -uninstall
    $ puma-dev -install
    ```

### config/master.key

Fins us to get this file.

## Docker, run and deploy

### Start docker

Remember to run docker-sync before running docker-compose

```shell
$ gem i docker-sync
$ docker-sync start
```

If `docker-sync start` return errors, just retry 2-3 times.

After docker-sync all success, run docker-compose.

```shell
$ docker-compose up -d
```

Enter docker and run `bin/server`.

```shell
$ docker-compose exec app bash
$ bin/server # already in docker
```

Open browser https://new-amis.moedict.test/ .

### Stop Docker

```shell
$ docker-compose down
$ docker-sync stop
```

### Rebuild Docker or update docker

```shell
$ docker-compose down
$ docker-compose up --build -d
```

### Check production and deploy

Enter docker and run precompile.

```shell
$ docker-compose exec app bash
$ bin/precompile # already in docker
$ bin/server production # already in docker
```

Open browser https://new-amis.moedict.test/ and check everything ok.

Remember to commit precompile assets files and then push to middle2.

```shell
$ git push m2 main:master && curl https://new-amis.moedict.tw/up
```

### When you need a debugger

You should see those info when starting docker.

```
DEBUGGER: Debugger can attach via UNIX domain socket (/tmp/rdbg-0/rdbg-NNN)
```

NNN is a 3-digit number that changes every time.

Enter docker and run rdbg command.

```shell
$ docker-compose exec app bash
$ bundle exec rdbg -a rdbg-NNN # already in docker
```

Please see https://guides.rubyonrails.org/debugging_rails_applications.html , and https://github.com/ruby/debug for more details.

### If your debugger gets stuck

Try to input `c` to run continuely and then `ctrl+c`, input `q` to exit.

If still, just run `$ docker-compose restart app`.

## API

v1 format is for legacy version.

v2 format is for 2024 version.

TODO

### API endpoints

### JSON format

## 開發影片紀錄

影片列表：過往 g0v 大小黑客松的提案與成果發表，[YouTube 影片列表](https://www.youtube.com/playlist?list=PLlkbkFcgp8UtgNZbPvCBV-k1Bl6d1HunE)。

## LICENSE 授權
### 辭典授權

* 蔡中涵阿美語大辭典，由蔡中涵博士 (Safulo Arik Cikatopay) 提供，採用 CC BY-NC-SA 3.0 TW 授權。
* 吳明義阿美族語辭典，由吳明義教授 (Namoh Rata) 家人提供，採用 CC BY-NC-SA 4.0 國際 授權。
* 方敏英阿美語字典（Virginia Fey 編著），由台灣聖經公會提供紙本，並經由鄉民OCR電子化，採用 CC BY-NC 授權。字典掃描檔案[雲端連結在此](https://drive.google.com/drive/folders/19mHnWh81z-Ah8XhI8w6NwCrnsetkHrns?usp=sharing)
* 博利亞潘世光神父阿美語-法語、阿美語-漢語字典，由天主教巴黎外方會的博利亞神父 (Louis Pourrias)、潘世光神父 (Maurice Poinsot) 提供，採用 CC BY-NC 授權。阿美語-漢語字典掃描檔案[雲端連結在此](https://drive.google.com/drive/folders/1kHIf5Nl9r9f3wg43lelKFUbrnZg_yzHy?usp=sharing)
* 原住民族語言線上辭典，由財團法人原住民族語言研究發展基金會授權阿美語萌典網站使用。
* 學習詞表無版權限制。
* 以上授權書請見[雲端資料夾](https://drive.google.com/drive/folders/1LChvSXEdMpxv0I4u3JoSRZL-GfiEXKgo?usp=sharing)

### 本站包含下列第三方元件

* jQuery 及 jQuery UI 由 OpenJS Foundation 提供，採用 MIT 授權。
* Font Awesome Free 字型由 Fonticons, Inc. 提供，Icons 採用 CC BY 4.0 授權，Fonts 採用 SIL OFL 1.1 授權。

### CC0 1.0 公眾領域貢獻宣告

作者 唐鳳、小蟹、Lafin 在法律許可的範圍內，拋棄此著作依著作權法所享有之權利，包括所有相關與鄰接的法律權利，並宣告將該著作貢獻至公眾領域。

https://creativecommons.org/publicdomain/zero/1.0/deed.zh-hant
