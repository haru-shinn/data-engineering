# dbt機能のお試し

## DBT Contract

- 対象のモデルのデータ型や制約が定義通りであるかを保証するための機能。
- dbt run 実行時に、定義した data_types や constraint を条件にチェックを行う。
- BigQueryでは、not_null しか適用されないので、dbt test のみでよさそう。一旦、martテーブルには not_null のみ適用した。

## DBT Unit Test

- 変換後のデータが定義された制約を満たしているかどうかをチェックするための機能。
- mart, fctテーブルに何個か適用した。

## DBT Osmosis

- メタデータ管理をしているyamlを管理する機能。

## dbt-colibri

- カラムレベルリネージを生成する
- 正確にはdbtの機能ではなくPythonのライブラリ

[URL](https://qiita.com/kobayashin/items/96552e9a395a835c38a6)

```bash
# インストール
pip install dbt-colibri
# リネージ生成のためのメタデータ作成
dbt compile
dbt docs generate
# リネージ生成
colibri generate
```
