# データモデル（基幹系/OLTP）

- [[目次]]
- [[データモデリング（基幹系・OLTP）]]

## 演習

**題材：旅客船会社の予約管理**

実態と関連
 - 旅客
   - 旅客ID
   - 旅客名
   - 生年月日
   - 性別
   - メールアドレス
 - 船
   - 船ID
   - 船名前
   - 全長
   - 総トン数
   - 運用開始日
   - 運用終了日
 - 客室
   - 船ID
   - 客室クラス
   - 客室数（客室クラス毎）
 - 航路
   - 航路ID
   - 出発港
   - 到着港
   - 航路順番（A港→B港→C港とする場合：A港→B港を1、B港→C港を2とする。）
 - 港
   - 港ID
   - 港名
   - 県
   - 市
   - 住所（都道府県+市区町村+番地など）
 - 都道府県
   - 都道府県コード
   - 都道府県名
 - 市区町村
   - 市区町村コード
   - 市区町村名
 - 運行
   - 航路ID
   - 出発港ID
   - 到着港ID
   - 船ID
 - 予約
   - 予約ID
   - 予約日
   - 運行日
   - 予約者名
   - 出発港
   - 到着港
   - 客室クラス
   - 客室番号
   - 支払い金額
- 乗船
  - 乗船ID
  - 運行日
  - 出発港ID
  - 到着港ID
  - 予約者名
  - 乗船FLG

**ER図**

```mermaid
erDiagram

    passengers {
        string passenger_id PK "旅客ID"
        string passenger_name "旅客名"
        date date_birth "生年月日"
        string gender "性別"
        string email "メールアドレス"
    }

    ships {
        string ship_id PK "船ID"
        string ship_name "船名前"
        float length "全長"
        integer gross_tonnage "総トン数"
        date start_date "運用開始日"
        date end_date "運用終了日"
    }

    rooms {
        string room_id PK "部屋ID"
        string ship_id FK "船ID"
        string room_class "客室クラス"
        integer room_count "客室数"
    }

    routes {
        string route_id PK "航路ID"
        string departure_port_id FK "出発港"
        string arrival_port_id FK "到着港"
        integer route_order "航路順番"
    }

    ports {
        string port_id PK "港ID"
        string port_name "港名"
        string prefecture_code FK "都道府県コード"
        string city_code FK "市区町村コード"
        string address "住所詳細"
    }

    prefectures {
        string pref_code PK "都道府県コード"
        string pref_name "都道府県名"
    }

    cities {
        string city_code PK "市区町村コード"
        string pref_code FK "都道府県コード"
        string city_name "市区町村名"
    }

    schedule {
        string schedule_id PK "運行ID"
        string route_id FK "航路ID"
        string ship_id FK "船ID"
        date departure_date "運行日"
    }

    reservations {
        string reservation_id PK "予約ID"
        string passenger_id FK "旅客ID"
        string schedule_id FK "運行ID"
        date reservation_date "予約日"
        string root_id "運行ルート"
        string room_class "客室クラス"
        string room_number "客室番号"
        integer payment_amount "支払い金額"
    }

    boarding {
        string boarding_id PK "乗船ID"
        string reservation_id FK "予約ID"
        boolean boarding_flg "乗船FLG"
    }


    prefectures ||--o{ cities: "所在する"
    cities ||--o{ ports: "所在する"
    ports ||--o{ routes: "出発・到着する"

    ships ||--o{ rooms: "保有する"
    ships ||--o{ schedule: "割り当てられる"
    routes ||--o{ schedule: "運行計画となる"   

    passengers ||--o{ reservations: "予約する"
    schedule ||--o{ reservations: "予約対象となる"

    reservations ||--|| boarding: "搭乗する"
```
