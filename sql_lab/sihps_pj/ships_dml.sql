/* 船の予約管理用のDML */

/* 乗客テーブル */
INSERT INTO SHIPS.PASSENGERS VALUES
()
;

/* 船マスタ（基本情報）テーブル */
INSERT INTO SHIPS.SHIPS (ship_id, ship_name, length, width, gross_tonnage, service_speed, max_passenger_capacity, start_date, end_date) VALUES
('S001', 'AppleMaru', 200.6, 27.1, 14015, 23, 443, '2025-05-10', '9999-12-31')
, ('S002', 'BananaMaru', 200.6, 27.1, 14015, 23, 443, '2025-06-14', '9999-12-31')
, ('S003', 'OrangeMaru', 202.1, 28.1, 15301, 20, 114, '2023-01-10', '9999-12-31')
, ('S004', 'GrapeMaru', 202.1, 28.1, 15301, 20, 114, '2023-03-05', '9999-12-31')
;

/* 車両区分マスタテーブル */
INSERT INTO SHIPS.VEHICLE_TYPES (type_code, type_name, length_limit, displacement_limit) VALUES
('CAR_SMALL', '軽自動車', 5.0, 0)
, ('CAR_REG', '普通車', 6.0, 0)
, ('TRACK_SMALL', '軽トラック', 5.0, 0)
, ('TRUCK_REG', '普通トラック', 9.0, 0)
, ('TRUCK_BIG', '大型トラック', 13.0, 0)
, ('MOT_CY_SMALL', '二輪（50cc以下）', 0.0, 50)
, ('MOT_CY_REG', '二輪（400cc以下）', 0.0, 400)
, ('MOT_CY_BIG', '二輪（750cc以下）', 0.0, 750)
, ('MOT_CY_HIGH_BIG', '二輪（750cc越）', 0.0, 9999)
, ('BICYCLE', '自転車', 0.0, 0)
;

/* 船別積載能力テーブル */
-- AppleMaru(S001), BananaMaru(S002)用
-- 大型トラック140台、乗用車150台、バイク40台の要件を按分
-- トラック、乗用車、バイク内で枠の流用が可能。ただし、最大積載量は越えない。
INSERT INTO SHIPS.SHIP_CAPACITIES (ship_id, type_code, max_capacity) VALUES
  ('S001', 'TRUCK_BIG', 130)
, ('S001', 'TRUCK_REG', 10)
, ('S001', 'TRUCK_SMALL', 5)
, ('S001', 'CAR_REG', 120)
, ('S001', 'CAR_SMALL', 30)
, ('S001', 'MOT_CY_HIGH_BIG',  5)
, ('S001', 'MOT_CY_BIG', 10)
, ('S001', 'MOT_CY_REG', 15)
, ('S001', 'MOT_CY_SMALL', 10)
, ('S001', 'BICYCLE', 10);

-- BananaMaruはAppleMaruと同じ設定
INSERT INTO SHIPS.SHIP_CAPACITIES (ship_id, type_code, max_capacity)
SELECT 'S002', type_code, max_capacity FROM SHIPS.SHIP_CAPACITIES WHERE ship_id = 'S001';

-- OrangeMaru(S003), GrapeMaru(S004)用
-- 大型トラック170台、乗用車20台、バイク20台の要件を按分
-- トラック、乗用車、バイク内で枠の流用が可能。ただし、最大積載量は越えない。
INSERT INTO SHIPS.SHIP_CAPACITIES (ship_id, type_code, max_capacity) VALUES
  ('S003', 'TRUCK_BIG',       160)
, ('S003', 'TRUCK_REG',        10)
, ('S003', 'TRUCK_SMALL',       0)
, ('S003', 'CAR_REG',          15)
, ('S003', 'CAR_SMALL',         5)
, ('S003', 'MOT_CY_HIGH_BIG',   2)
, ('S003', 'MOT_CY_BIG',        3)
, ('S003', 'MOT_CY_REG',       10)
, ('S003', 'MOT_CY_SMALL',      5)
, ('S003', 'BICYCLE',           5);

-- GrapeMaruはOrangeMaruと同じ設定
INSERT INTO SHIPS.SHIP_CAPACITIES (ship_id, type_code, max_capacity)
SELECT 'S004', type_code, max_capacity FROM SHIPS.SHIP_CAPACITIES WHERE ship_id = 'S003';


/* 客室クラス定義マスタテーブル */
INSERT INTO SHIPS.ROOM_CLASS_MASTER VALUES
('SW', 'スイート', 2, '豪華個室。「室単位」で予約。')
, ('DX', 'デラックス', 4, '家族向け個室。「室単位」で予約。1名でも「1室利用」ができる（貸切料が発生する）。')
, ('TR', 'ツーリング（寝台）', 1, '一人用個室。「室単位」で予約。')
, ('EC', 'エコノミー（雑魚寝）', 20, '大部屋。「エリアの定員」で管理。部屋番号が固定されない。')
, ('DR', 'ドライバー室', 4, 'トラック運転手専用')
;

/* 船別客室設定テーブル */
-- total_occupancyは自動生成（room_count*capacity_per_room）されるため、INSERT文で省略している。
INSERT INTO SHIPS.SHIP_ROOM_CLASSES (ship_id, room_class_id, room_count, capacity_per_room) VALUES
('S001', 'SW', 5, 2), ('S001', 'DX', 22, 4), ('S001', 'TR', 105, 1), ('S001', 'EC', 10, 20), ('S001', 'DR', 10, 4)
, ('S002', 'SW', 5, 2), ('S002', 'DX', 22, 4), ('S002', 'TR', 105, 1), ('S002', 'EC', 10, 20), ('S002', 'DR', 10, 4)
, ('S003', 'SW', 1, 2), ('S003', 'DX', 3, 4), ('S003', 'TR', 20, 1), ('S003', 'EC', 2, 20), ('S003', 'DR', 10, 4)
, ('S004', 'SW', 1, 2), ('S004', 'DX', 3, 4), ('S004', 'TR', 20, 1), ('S004', 'EC', 2, 20), ('S004', 'DR', 10, 4)
;

/* 客室マスタテーブル */
INSERT INTO SHIPS.ROOMS (room_id, ship_id, room_class_id, room_no)
SELECT
  ship_id || room_class_id || LPAD(n::text, 3, '0') AS room_id
  , ship_id
  , room_class_id
  , LPAD(n::text, 2, '0') AS room_no
FROM
  SHIPS.SHIP_ROOM_CLASSES
  , generate_series(1, 250) AS n
WHERE
  n <= room_count
;

/* 航路テーブル */
INSERT INTO SHIPS.ROUTES (route_id, departure_port_id, arrival_port_id) VALUES
('R1', 'P1', 'P3')
, ('R2', 'P1', 'P2')
, ('R3', 'P2', 'P3')
;

/* 区間テーブル */
INSERT INTO SHIPS.SECTIONS (section_id, departure_port_id, arrival_port_id, standard_time_required, notice) VALUES
('S1', 'P1', 'P3', '21時間45分', '下り(西行)')
, ('S2', 'P3', 'P1', '21時間00分','上り東行')
, ('S3', 'P1', 'P2', '18時間45分', '上り北行')
, ('S4', 'P2', 'P1', '18時間30分', '下り南行')
;

/* 航路区間構成テーブル */
INSERT INTO SHIPS.ROUTE_SECTIONS (section_id, route_id) VALUES
('S1', 'R1')
, ('S2', 'R1')
, ('S3', 'R2')
, ('S4', 'R2')
, ('S1', 'R3')
, ('S2', 'R3')
, ('S3', 'R3')
, ('S4', 'R3')
;

/* 港テーブル */
INSERT INTO SHIPS.PORTS VALUES
('P1', '横須賀港', '神奈川県', '神奈川県横須賀市XXX')
, ('P2', '苫小牧港', '北海道', '北海道苫小牧市YYY')
, ('P3', '新門司港', '福岡県', '福岡県北九州市ZZZ')
;

/* 都道府県テーブル */
INSERT INTO SHIPS.PREFECTURES VALUES
()
;

/* 市区町村テーブル */
INSERT INTO SHIPS.CITIES VALUES
()
;

/* 運行スケジュールテーブル */
SELECT s.schedule_id, s.route_id, s.section_id, s.departure_time, s.arrival_time, s.ship_id, p1.port_name, p2.port_name
FROM ships.schedule AS s
  INNER JOIN ships.routes AS r ON s.route_id = r.route_id
  INNER JOIN ships.ports AS p1 ON p1.port_id = r.departure_port_id
  INNER JOIN ships.ports AS p2 ON p2.port_id = r.arrival_port_id
WHERE s.route_id = 'R2' -- AND s.ship_id = 'S003'
ORDER BY s.schedule_id, s.route_id, s.section_id
;

DELETE FROM SHIPS.SCHEDULE;
INSERT INTO SHIPS.SCHEDULE (
    schedule_id, route_id, section_id, departure_date, arrival_date, departure_time, arrival_time, ship_id
)
WITH date_series AS (
  SELECT
    CAST(d AS DATE) as d_date
    , (CAST(d AS DATE) - CAST('2026-01-17' AS DATE)) as elapsed_days
  FROM
    generate_series('2026-01-17'::date, '2026-01-31'::date, '1 day'::interval) d
),
raw_data AS (
  -- 1. AppleMaru: 苫小牧 ↔ 横須賀 (R2)
  -- 到着翌日に折り返すサイクル (S4 -> 休み -> S3 -> 休み)
  SELECT d_date, 'S001' as s_id, 'R2' as rout,
    CASE (elapsed_days % 4)
      WHEN 0 THEN 'S4' WHEN 2 THEN 'S3' ELSE NULL
    END as sect FROM date_series
  UNION ALL
  -- 2. BananaMaru: 新門司 ↔ 横須賀 (R1)
  -- 到着翌日に折り返すサイクル (S2 -> 休み -> S1 -> 休み)
  SELECT d_date, 'S002' as s_id, 'R1' as rout,
    CASE (elapsed_days % 4)
      WHEN 0 THEN 'S2' WHEN 2 THEN 'S1' ELSE NULL
    END as sect FROM date_series
  UNION ALL
  -- 3. OrangeMaru: R3 直通 (苫小牧 -> 横須賀(経由) -> 新門司)
  -- 到着当日に折り返す
  SELECT d_date, 'S003' as s_id, 'R3' as rout,
    CASE (elapsed_days % 4)
      WHEN 0 THEN 'S4' WHEN 1 THEN 'S1' WHEN 2 THEN 'S2' WHEN 3 THEN 'S3'
    END as sect FROM date_series
  UNION ALL
  -- 4. GrapeMaru: R3 直通 (新門司 -> 横須賀(経由) -> 苫小牧)
  -- 到着当日に折り返す
  SELECT d_date, 'S004' as s_id, 'R3' as rout,
    CASE (elapsed_days % 4)
      WHEN 2 THEN 'S4' WHEN 3 THEN 'S1' WHEN 0 THEN 'S2' WHEN 1 THEN 'S3'
    END as sect FROM date_series
)
SELECT
  to_char(d_date, 'YYYYMMDD') || s_id || coalesce(sect, 'XX') as schedule_id
  , rout as route_id
  , sect as section_id
  , d_date as departure_date
  , d_date + 1 as arrival_date
  , CASE
      WHEN sect = 'S1' THEN (d_date + '20:30:00'::time)
      WHEN sect = 'S2' THEN (d_date + '22:15:00'::time)
      WHEN sect = 'S3' THEN (d_date + '22:30:00'::time)
      WHEN sect = 'S4' THEN (d_date + '23:00:00'::time)
    END as departure_time
  , CASE
      WHEN sect = 'S1' THEN (d_date + 1 + '18:15:00'::time)
      WHEN sect = 'S2' THEN (d_date + 1 + '19:15:00'::time)
      WHEN sect = 'S3' THEN (d_date + 1 + '17:15:00'::time)
      WHEN sect = 'S4' THEN (d_date + 1 + '17:30:00'::time)
    END as arrival_time
  , s_id as ship_id
FROM
  raw_data
WHERE
  sect IS NOT NULL
;

/* 予約基本情報テーブル */
INSERT INTO SHIPS.RESERVATIONS VALUES
()
;

/* 予約明細情報テーブル */
INSERT INTO SHIPS.RESERVATION_DETAILS VALUES
()
;

/* 在庫テーブル */
INSERT INTO SHIPS.INVENTRY VALUES
()
;

/* 発券テーブル */
INSERT INTO SHIPS.TICKETING VALUES
()
;

/* 搭乗実績テーブル */
INSERT INTO SHIPS.BOARDING VALUES
()
;

/* 運賃テーブル */
INSERT INTO SHIPS.FARE_MASTER VALUES
()
;