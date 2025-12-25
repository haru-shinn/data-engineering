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

    %% 会員テーブル（会員登録された方の情報）
    users {
      string user_id PK "会員ID"
      string user_name "会員氏名"
      string password "パスワード"
      string phone "電話番号"
      string email "メールアドレス"
      integer point "保有point"
    }

    %% 船テーブル（保有している船の情報）
    ships {
        string ship_id PK "船ID"
        string ship_name "船名"
        float length "全長"
        integer gross_tonnage "総トン数"
        date start_date "運用開始日"
        date end_date "運用終了日"
    }

    %% 部屋クラステーブル（各船に用意されている客室クラスの情報）
    room_classes {
        string ship_id PK, FK "船ID"
        string room_class_id PK "客室クラスID"
        string room_class_name "客室クラス名"
        integer capacity_per_room "1室あたりの定員"
        integer room_count "客室数（船＋クラス単位）"
    }

    %% 部屋テーブル（各船に用意されている客室の情報）
    rooms {
      string room_id PK "部屋ID（船ID+連番）"
      string room_class_id FK "客室クラスID"
      string room_no "部屋番号"
    }

    %% 航路テーブル（運行する航路の情報）
    routes {
        string route_id PK "航路ID"
        string section_id PK "区間ID"
        string round_trip_section PK "往路区分"
        string departure_port_id FK "出発港"
        string arrival_port_id FK "到着港"
    }

    %% 港テーブル（港の情報）
    ports {
        string port_id PK "港ID"
        string port_name "港名"
        string prefecture_code FK "都道府県コード"
        string city_code FK "市区町村コード"
    }

    %% 都道府県テーブル（都道府県名の情報）
    prefectures {
        string prefecture_code PK "都道府県コード"
        string prefecture_name "都道府県名"
    }

    %% 市区町村テーブル（市区町村の情報）
    cities {
        string city_code PK "市区町村コード"
        string prefecture_code FK "都道府県コード"
        string city_name "市区町村名"
    }

    %% 運行スケジュールテーブル（運行スケジュールの情報）
    schedule {
        string route_id PK,FK "航路ID"
        string section_id PK,FK "区間ID"
        string round_trip_section PK,FK "往路区分"
        date departure_date PK "出発日"
        date arrival_date "到着日"
        timestamp departure_time PK "出発時刻"
        timestamp arrival_time "到着時刻"
        string ship_id FK "船ID"
    }

    %% 予約基本情報テーブル（ヘッダー情報：誰が、いつ、どの便を）
    reservations {
        string reservation_id PK "予約ID"
        string user_id "旅客ID(任意)"
        string schedule_id FK "運行ID"
        string rep_name "代表者名"
        string rep_email "代表者連絡先"
        date reservation_date "予約日"
    }

    %% 予約明細情報テーブル（ボディ情報：誰が、どの区分で、どの部屋か）
    reservation_details {
        string reservation_id PK,FK "予約ID"
        string detail_id PK "明細ID"
        string passenger_id "旅客ID(任意)"
        string passenger_type "区分(大人/小人)"
        string room_class "希望クラス"
        integer applied_fare "適用運賃"
    }

    %% 在庫テーブル（残りの部屋数）
    inventry {
        string route_id PK,FK "航路ID"
        string section_id PK,FK "区間ID"
        string round_trip_section PK,FK "往路区分"
        date departure_date PK "出発日"
        timestamp departure_time PK "出発時刻"
        string ship_id FK "船ID"
        integer room_count "客室数（船＋クラス単位）"
        integer remaining_romm_count "残室数（船＋クラス単位）"
    }

    %% 発券テーブル（発券情報）
    ticketing {
      string ticket_id PK "発券ID"
      string reservation_id FK "予約ID"
      string ticket_type "搭乗券種別"
    }

    %% 搭乗実績テーブル（搭乗情報）
    boarding {
        string boarding_id PK "乗船ID"
        string reservation_id FK "予約ID"
        string ticket_id FK "発券ID"
        boolean boarding_flg "乗船FLG"
    }

    %% 運賃テーブル（運賃タイプと運賃の情報）
    fare_master {
        string route_id PK, FK "航路ID"
        string section_id PK, FK "区間ID"
        string room_class PK "客室クラス"
        integer fare "金額"
    }

    prefectures ||--o{ cities: "所在する"
    cities ||--o{ ports: "所在する"
    ports ||--o{ routes: "出発・到着する"

    ships ||--o{ room_classes: "保有する"
    room_classes ||--o{ rooms : "部屋情報を保有する"
    ships ||--o{ schedule: "割り当てられる"
    routes ||--o{ schedule: "運行計画となる"
    fare_master ||--o{ room_classes: "計算する"
    fare_master ||--o{ routes: "計算する"

    users ||--o{ reservations : "会員情報の確認"
    schedule ||--o{ reservations: "予約対象となる"
    schedule ||--|| inventry: "在庫の確認"
    reservations ||--|{ reservation_details : "人数分作成する"
    reservations ||--|{ ticketing: "発券する"
    ticketing ||--|| boarding: "搭乗する"
```
