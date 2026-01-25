/*
船の予約管理用のDDL

データベース：postgreSQL
*/

/* ================================================== */

CREATE DATABASE WORK_DB;
CREATE SCHEMA SHIPS;

/* ================================================== */

-- 乗客テーブル
DROP TABLE IF EXISTS SHIPS.PASSENGERS;
CREATE TABLE IF NOT EXISTS SHIPS.PASSENGERS (
  passenger_id CHAR(8) PRIMARY KEY
  , passenger_name VARCHAR(256) NOT NULL
  , birth_date DATE
  , gender CHAR(1)
  , password VARCHAR(256)
  , phone_number VARCHAR(16)
  , email VARCHAR(256)
  , point INTEGER
);

-- 船マスタ（基本情報）テーブル
DROP TABLE IF EXISTS SHIPS.SHIPS CASCADE;
CREATE TABLE IF NOT EXISTS SHIPS.SHIPS (
  ship_id CHAR(4) PRIMARY KEY
  , ship_name VARCHAR(16) NOT NULL
  , length DECIMAL(5, 2) NOT NULL
  , width DECIMAL(4, 2) NOT NULL
  , gross_tonnage INTEGER NOT NULL
  , service_speed INTEGER NOT NULL
  , max_passenger_capacity INTEGER NOT NULL
  , start_date DATE NOT NULL
  , end_date DATE
);

-- 車両区分マスタテーブル
DROP TABLE IF EXISTS SHIPS.VEHICLE_TYPES CASCADE;
CREATE TABLE SHIPS.VEHICLE_TYPES (
  type_code VARCHAR(16) PRIMARY KEY -- 車両区分（'CAR_REG', 'CAR_SMALL', 'TRUCK_L' など）
  , type_name VARCHAR(32) NOT NULL  -- 車両名（'普通車', '軽自動車'）
  , length_limit DECIMAL(4, 2)        -- 車長（車は長さで判定（5.0mまでなど））
  , displacement_limit INTEGER        -- 排気量（二輪車は排気量で判定（50cc以下など））
);

-- 船別積載能力テーブル
DROP TABLE IF EXISTS SHIPS.SHIP_CAPACITIES CASCADE;
CREATE TABLE SHIPS.SHIP_CAPACITIES (
  ship_id CHAR(4) NOT NULL
  , type_code VARCHAR(12) NOT NULL
  , max_capacity INTEGER NOT NULL
  , PRIMARY KEY (ship_id, type_code)
  , FOREIGN KEY (ship_id) REFERENCES SHIPS.SHIPS(ship_id)
  , FOREIGN KEY (type_code) REFERENCES SHIPS.VEHICLE_TYPES(type_code)
);

-- 客室クラス定義マスタテーブル
DROP TABLE IF EXISTS SHIPS.ROOM_CLASS_MASTER CASCADE;
CREATE TABLE IF NOT EXISTS SHIPS.ROOM_CLASS_MASTER (
  room_class_id CHAR(2)
  , room_class_name VARCHAR(16)
  , capacity_per_room INTEGER
  , notice VARCHAR(256)
  , PRIMARY KEY (room_class_id)
  , UNIQUE (room_class_id, capacity_per_room)
);

-- 船別客室設定テーブル
DROP TABLE IF EXISTS SHIPS.SHIP_ROOM_CLASSES CASCADE;
CREATE TABLE IF NOT EXISTS SHIPS.SHIP_ROOM_CLASSES (
  ship_id CHAR(4)
  , room_class_id CHAR(2)
  , room_count INTEGER
  , capacity_per_room INTEGER
  , total_occupancy INTEGER GENERATED ALWAYS AS (room_count * capacity_per_room) STORED
  , PRIMARY KEY (ship_id, room_class_id)
  , FOREIGN KEY (room_class_id, capacity_per_room) REFERENCES ships.room_class_master(room_class_id, capacity_per_room)
);

-- 客室マスタテーブル
DROP TABLE IF EXISTS SHIPS.ROOMS CASCADE;
CREATE TABLE IF NOT EXISTS SHIPS.ROOMS (
  room_id CHAR(9)          -- 船ID(4桁) + クラスID(2桁) + 連番(3桁)
  , ship_id CHAR(4)
  , room_class_id CHAR(2)
  , room_no CHAR(3)        -- 連番
  , PRIMARY KEY (room_id)
  , FOREIGN KEY (ship_id, room_class_id) REFERENCES ships.ship_room_classes(ship_id, room_class_id)
);

-- 航路テーブル
DROP TABLE IF EXISTS SHIPS.ROUTES;
CREATE TABLE IF NOT EXISTS SHIPS.ROUTES (
  route_id CHAR(3) PRIMARY KEY
  , departure_port_id CHAR(2) REFERENCES ships.ports(port_id)
  , arrival_port_id CHAR(2) REFERENCES ships.ports(port_id)
);

-- 区間テーブル
DROP TABLE IF EXISTS SHIPS.SECTIONS;
CREATE TABLE IF NOT EXISTS SHIPS.SECTIONS (
  section_id CHAR(2) PRIMARY KEY
  , departure_port_id CHAR(2) REFERENCES ships.ports(port_id)
  , arrival_port_id CHAR(2) REFERENCES ships.ports(port_id)
  , standard_time_required CHAR(8)
  , notice CHAR(256)
);

-- 航路区間構成テーブル
DROP TABLE IF EXISTS SHIPS.ROUTE_SECTIONS;
CREATE TABLE IF NOT EXISTS SHIPS.ROUTE_SECTIONS (
  section_id CHAR(2) REFERENCES ships.sections(section_id)
  , route_id CHAR(2) REFERENCES ships.routes(route_id)
  , PRIMARY KEY (section_id, route_id)
);

-- 港テーブル
DROP TABLE IF EXISTS SHIPS.PORTS CASCADE;
CREATE TABLE IF NOT EXISTS SHIPS.PORTS (
  port_id CHAR(2) PRIMARY KEY
  , port_name VARCHAR(128)
  , prefecture_name VARCHAR(64)
  -- , prefecture_code CHAR(2) REFERENCES ships.prefectures(prefecture_code)
  -- , city_code CHAR(3) REFERENCES ships.cities(city_code)
  , address VARCHAR(256)
);

/*
DROP TABLE IF EXISTS SHIPS.PREFECTURES CASCADE;
CREATE TABLE IF NOT EXISTS SHIPS.PREFECTURES (
  prefecture_code CHAR(2) PRIMARY KEY
  , prefecture_name VARCHAR(16)
);

DROP TABLE IF EXISTS SHIPS.CITIES CASCADE;
CREATE TABLE IF NOT EXISTS SHIPS.CITIES (
  city_code CHAR(3) PRIMARY KEY
  , prefecture_code CHAR(2) REFERENCES ships.prefectures(prefecture_code)
  , city_name VARCHAR(16)
);
*/

-- 運行スケジュールテーブル
DROP TABLE IF EXISTS SHIPS.SCHEDULE CASCADE;
CREATE TABLE IF NOT EXISTS SHIPS.SCHEDULE (
  schedule_id CHAR(14) PRIMARY KEY
  , route_id CHAR(2) REFERENCES ships.routes(route_id)
  , section_id CHAR(2) REFERENCES ships.sections(section_id)
  , departure_date DATE
  , arrival_date DATE
  , departure_time timestamp
  , arrival_time timestamp
  , ship_id CHAR(4) REFERENCES ships.ships(ship_id)
);

-- 予約基本情報テーブル
DROP TABLE IF EXISTS SHIPS.RESERVATIONS CASCADE;
CREATE TABLE IF NOT EXISTS SHIPS.RESERVATIONS (
  reservation_id CHAR(12) PRIMARY KEY   -- 予約ID（予約日+連番 YYYYMMDD-XXX）
  , rep_name CHAR(256)                 -- 予約者名
  , rep_email CHAR(256)                -- 予約者の連絡先
  , reservation_date DATE              -- 予約日
  , vehicle_type_code VARCHAR(16)      -- 車種区分（利用しない場合は、Nullが入る）
  , FOREIGN KEY (vehicle_type_code) REFERENCES SHIPS.VEHICLE_TYPES(type_code)
);

-- 予約明細情報テーブル
DROP TABLE IF EXISTS SHIPS.RESERVATION_DETAILS CASCADE;
CREATE TABLE IF NOT EXISTS SHIPS.RESERVATION_DETAILS (
  reservation_id CHAR(12) REFERENCES ships.reservations(reservation_id)  -- 予約ID
  , detail_id CHAR(3)                                                   -- 予約明細ID（予約人数分採番される）
  , section_id CHAR(2) REFERENCES ships.sections(section_id)            -- 区間ID
  , schedule_id CHAR(14) REFERENCES ships.schedule(schedule_id)         -- スケジュールID
  , passenger_id CHAR(8)                                                -- 旅客ID（任意）
  , passenger_type CHAR(8)                                              -- 大人/子供 区分
  , ship_id CHAR(4) REFERENCES ships.ships(ship_id)                     -- 船ID
  , room_class_id CHAR(2)                                               -- 客室クラスID
  , applied_fare INTEGER                                                -- 適用料金
  , PRIMARY KEY (reservation_id, detail_id, section_id)
  , FOREIGN KEY (room_class_id) REFERENCES SHIPS.ROOM_CLASS_MASTER(room_class_id)
);

-- 在庫テーブル
DROP TABLE IF EXISTS SHIPS.INVENTRY CASCADE;
CREATE TABLE IF NOT EXISTS SHIPS.INVENTRY (
  schedule_id CHAR(14)
  , section_id CHAR(2)
  , room_class_id CHAR(2)
  , room_count INTEGER
  , remaining_room_cnt INTEGER
  , num_of_people INTEGER
  , remaining_num_of_people INTEGER
  , PRIMARY KEY (schedule_id, section_id, room_class_id)
  , FOREIGN KEY (room_class_id) REFERENCES SHIPS.ROOM_CLASS_MASTER(room_class_id)
  , FOREIGN KEY (section_id) REFERENCES SHIPS.SECTIONS(section_id)
);

-- 車両在庫テーブル
DROP TABLE IF EXISTS SHIPS.VEHICLE_INVENTRY CASCADE;
CREATE TABLE SHIPS.VEHICLE_INVENTRY (
  schedule_id CHAR(14)
  , section_id CHAR(2)
  , type_code VARCHAR(16)       -- 車種区分（'CAR_REG', 'BIKE_LARGE' 等）
  , max_capacity INTEGER        -- 最大積載量（SHIP_CAPACITIESからコピー）
  , remaining_capacity INTEGER  -- 残り台数
  , PRIMARY KEY (schedule_id, type_code)
  , FOREIGN KEY (type_code) REFERENCES SHIPS.VEHICLE_TYPES(type_code)
  , FOREIGN KEY (section_id) REFERENCES SHIPS.SECTIONS(section_id)
);

-- 発券テーブル
DROP TABLE IF EXISTS SHIPS.TICKETING;
CREATE TABLE IF NOT EXISTS SHIPS.TICKETING (
  ticket_id CHAR(8) PRIMARY KEY
  , reservation_id CHAR(8) REFERENCES ships.reservations(reservation_id)
  , ticket_type CHAR(2)
);

-- 搭乗実績テーブル
DROP TABLE IF EXISTS SHIPS.BOARDING;
CREATE TABLE IF NOT EXISTS SHIPS.BOARDING (
  boarding_id CHAR(8) PRIMARY KEY
  , reservation_id CHAR(8) REFERENCES ships.reservations(reservation_id)
  , boarding_flg boolean
);

-- 運賃テーブル
DROP TABLE IF EXISTS SHIPS.FARE_MASTER;
CREATE TABLE IF NOT EXISTS SHIPS.FARE_MASTER (
  room_class CHAR(2)
  , route_id CHAR(3) REFERENCES ships.routes(route_id)
  , ship_id CHAR(4) REFERENCES ships.ships(ship_id)
  , fare INTEGER
  , PRIMARY KEY (room_class, route_id)
);

/* ================================================== */

/*
空席照会ビューの作成

- 利用者の操作
  - 出港日と区間を入力する。
結果の表示
  - 出港日と+2日までの予約を表示する。
  - 出港日別、客室クラス別に金額と空席があるかを表示（〇、△、×）する。
  - 客室クラスを考慮することなく、車両在庫を表示（〇、△、×）する。
　　　　　　　　　　　
- 利用テーブル
  - inventry (在庫テーブル)
  - vehicle_inventry  (車両在庫テーブル)
  - schedule (運行スケジュールテーブル)
  - sections (区間テーブル)
  - ports (港テーブル)
  - ships (船マスタ（基本情報）テーブル)
  - room_class_master (客室クラス定義マスタテーブル)

- 表示する値
  - 出港日 (MM月DD日（DoW）) : schedule.departure_date
  - 出発港 : ports.port_name
  - 到着日 (MM月DD日（DoW）) : schedule.arrival_date
  - 到着港 : ports.port_name
  - 便名 : ships.ship_name
  - クラス名 : room_class_master.room_class_name
  - クラス別予約状況 : inventry.remaining_room_cnt, inventry.remaining_num_of_people
  - 車両予約状況（クラス別ではない） : vehicle_inventry.remaining_capacity

- 引数
  - 出港日（YYYY-MM-DD）
  - 区間（section_id）
*/
DROP VIEW ships.availability_v;
CREATE OR REPLACE VIEW ships.availability_v AS (
WITH summary_vehicle AS (
  SELECT
    schedule_id
    , SUM(CASE WHEN type_code = 'CAR_SMALL' THEN remaining_capacity ELSE 0 END) AS car_small_rem
    , SUM(CASE WHEN type_code = 'CAR_REG' THEN remaining_capacity ELSE 0 END) AS car_reg_rem
    , SUM(CASE WHEN type_code = 'TRUCK_SMALL' THEN remaining_capacity ELSE 0 END) AS truck_small_rem
    , SUM(CASE WHEN type_code = 'TRUCK_REG' THEN remaining_capacity ELSE 0 END) AS truck_reg_rem
    , SUM(CASE WHEN type_code = 'TRUCK_BIG' THEN remaining_capacity ELSE 0 END) AS truck_big_rem
    , SUM(CASE WHEN type_code = 'MOT_CY_SMALL' THEN remaining_capacity ELSE 0 END) AS mot_cy_small_rem
    , SUM(CASE WHEN type_code = 'MOT_CY_REG' THEN remaining_capacity ELSE 0 END) AS mot_cy_reg_rem
    , SUM(CASE WHEN type_code = 'MOT_CY_BIG' THEN remaining_capacity ELSE 0 END) AS mot_cy_big_rem
    , SUM(CASE WHEN type_code = 'MOT_CY_HIGH_BIG' THEN remaining_capacity ELSE 0 END) AS mot_cy_high_big_rem
    , SUM(CASE WHEN type_code = 'BICYCLE' THEN remaining_capacity ELSE 0 END) AS bicycle_rem
  FROM
    ships.vehicle_inventry
  GROUP BY 
    schedule_id
)
SELECT
  sc.schedule_id
  , sc.route_id
  , sc.departure_date
  , sc.departure_time
  , sc.arrival_date
  , sc.arrival_time
  , s.ship_name
  , rcm.room_class_name
  , sec.section_id
  , dep_port.port_name AS departure_port
  , arr_port.port_name AS arrival_port
  , i.remaining_room_cnt
  , i.room_count
  , CASE
      WHEN (CAST(remaining_room_cnt as FLOAT) / room_count) = 0 THEN '×'
      WHEN (CAST(remaining_room_cnt as FLOAT) / room_count) <= 0.2 THEN '△'
      WHEN (CAST(remaining_room_cnt as FLOAT) / room_count) <= 0.5 THEN '〇'
      ELSE '◎'
    END AS room_vacancy_rate
  , sv.car_small_rem
  , sv.car_reg_rem
  , sv.truck_small_rem
  , sv.truck_reg_rem
  , sv.truck_big_rem
  , sv.mot_cy_small_rem
  , sv.mot_cy_reg_rem
  , sv.mot_cy_big_rem
  , sv.mot_cy_high_big_rem
  , sv.bicycle_rem
FROM
  ships.schedule AS sc
  INNER JOIN ships.ships AS s ON sc.ship_id = s.ship_id
  INNER JOIN ships.sections AS sec ON sec.section_id = sc.section_id
  INNER JOIN ships.inventry AS i ON sc.schedule_id = i.schedule_id
  INNER JOIN ships.room_class_master AS rcm ON rcm.room_class_id = i.room_class_id
  LEFT JOIN summary_vehicle AS sv ON sv.schedule_id = sc.schedule_id
  INNER JOIN ships.ports AS dep_port ON dep_port.port_id = sec.departure_port_id
  INNER JOIN ships.ports AS arr_port ON arr_port.port_id = sec.arrival_port_id
ORDER BY
  sc.schedule_id, sc.ship_id
);
