# 更新與整理蔡中涵大辭典

## 更新

    ```bash
    cd tmp/dict
    rm -rf s
    rm s-list.txt
    cp -r ../../../amis-moedict/docs/s .
    ```

用 `docker-sync start` 然後 `docker-compose up -d` 啟動 docker。

用 `docker-compose exec app bash` 進入 docker。

    ```bash
    bin/rails import:safolu
    ```

## 刪除字詞

這段指令大概要跑五分鐘。

    ```bash
    cd tmp/dict
    find s -type f -name "*.json" -exec basename {} \; | sed 's/\.json$//' > s-list.txt
    ```

進入 docker，用 `bin/rails c` 進入 rails console。

    ```ruby
    list=File.read('tmp/dict/s-list.txt').split("\n");1
    d=Dictionary.find 1;1
    terms=d.terms.pluck(:lower_name).uniq;1
    terms-list # 一一確認檔案不存在、是否要修正，如檔名有空白、大小寫問題
    d.terms.where(lower_name: (terms-list)).destroy_all;1
    ```
