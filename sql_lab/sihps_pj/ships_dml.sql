/* 船の予約管理用のDML */

/* 乗客テーブル */
INSERT INTO SHIPS.PASSENGERS VALUES 
()
;

/* 船マスタテーブル */
INSERT INTO SHIPS.SHIPS (ship_id, ship_name, length, width, gross_tonnage, service_speed, max_passenger_capacity, start_date, end_date) VALUES 
('S001', 'AppleMaru', 200.6, 27.1, 14015, 23, 443, '2025-05-10', '9999-12-31')
, ('S002', 'BananaMaru', 200.6, 27.1, 14015, 23, 443, '2025-06-14', '9999-12-31')
, ('S003', 'OrangeMaru', 202.1, 28.1, 15301, 20, 114, '2023-01-10', '9999-12-31')
, ('S004', 'GrapeMaru', 202.1, 28.1, 15301, 20, 114, '2023-03-05', '9999-12-31')
;

/* 車両区分マスタ */
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

/* 船別積載能力 */
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


/* 客室クラス定義マスタ */
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
INSERT INTO SHIPS.ROUTES VALUES 
('R1', 'P1', 'P3')
, ('R2', 'P1', 'P2')
, ('R3', 'P2', 'P3')
;

/* 区間テーブル */
INSERT INTO SHIPS.SECTIONS VALUES 
('S1', 'P1', 'P3', '21時間45分', '下り(西行)')
, ('S2', 'P3', 'P1', '21時間00分','上り東行')
, ('S3', 'P1', 'P2', '18時間45分', '上り北行')
, ('S4', 'P2', 'P1', '18時間30分', '下り南行')
;

/* 航路区間構成テーブル */
INSERT INTO SHIPS.ROUTE_SECTIONS VALUES 
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
INSERT INTO SHIPS.SCHEDULE VALUES 
()
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