/* プロシージャ */

/* ======================================== */
/* 予約データ挿入用のプロシージャ */
DROP PROCEDURE IF EXISTS ships.insert_reservation
(DATE, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, INTEGER, TEXT, INTEGER);

CREATE OR REPLACE PROCEDURE ships.insert_reservation (
  p_departure_date DATE DEFAULT NULL
  , p_departure_port_id TEXT DEFAULT NULL
  , p_ship_id TEXT DEFAULT NULL
  , p_route_id TEXT DEFAULT NULL
  , p_passenger_id TEXT DEFAULT NULL
  , p_rep_name TEXT DEFAULT NULL
  , p_rep_email TEXT DEFAULT NULL
  , p_rep_passenger_type TEXT DEFAULT NULL
  , p_room_class_id TEXT DEFAULT NULL
  , p_room_class_reserve_cnt INTEGER DEFAULT 0
  , p_applied_fare INTEGER DEFAULT 0
  , p_vehicle_type TEXT DEFAULT NULL
  , p_vehicle_reserve_cnt INTEGER DEFAULT 0
)
LANGUAGE plpgsql
AS $$
DECLARE
  p_current_date DATE;
  p_res_id TEXT;
  upsert_count INTEGER;
  actual_upsert_count INTEGER;
  error_message TEXT;

BEGIN
  ----------------------------------------
  -- ルート判定
  -- ルート（R1,R2 と R3） によって、処理を変更する。
  -- R1,2の場合は、１区間目の処理を利用して、２区間目をスキップする。
  ----------------------------------------
  IF p_route_id = 'R3' THEN
    RAISE NOTICE 'ルートID: %', p_route_id;
  ELSE
    RAISE NOTICE 'ルートID: %', p_route_id;
  END IF;


  ----------------------------------------
  -- 更新処理で必要な値の取得
  ----------------------------------------
  SELECT CURRENT_DATE INTO  p_current_date;

  ----------------------------------------
  -- 更新対象の運行スケジュールの情報を取得
  ----------------------------------------
  CREATE TEMP TABLE target_sections ON COMMIT DROP AS
  SELECT schedule_id, section_id, ship_id
  FROM ships.schedule
  WHERE
    ship_id = p_ship_id
    AND route_id = p_route_id
    AND departure_date IN (p_departure_date, CAST(p_departure_date AS DATE) + CAST('1 days' AS INTERVAL))
  FOR UPDATE;

  SELECT COUNT(*) FROM target_sections INTO upsert_count;
  RAISE NOTICE '更新対象のレコード: %', upsert_count;

  ----------------------------------------
  -- 予約IDの作成
  ----------------------------------------
  CREATE SEQUENCE IF NOT EXISTS ships.reservation_seq START 1;
  p_res_id := TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(NEXTVAL('ships.reservation_seq')::TEXT, 3, '0');
  
  
  ----------------------------------------
  -- 部屋予約
  ----------------------------------------
  -- 予約基本情報テーブルへの挿入
  INSERT INTO ships.reservations (reservation_id, rep_name, rep_email, reservation_date, vehicle_type_code) 
  VALUES (p_res_id, p_rep_name, p_rep_email, p_current_date, p_vehicle_type);

 -- 予約明細情報テーブルへの挿入
  INSERT INTO ships.reservation_details (reservation_id, detail_id, section_id, schedule_id, passenger_type, ship_id, room_class_id, applied_fare)
  SELECT
    p_res_id
    , LPAD(gs.id::text, 3, '0')
    , ts.section_id
    , ts.schedule_id
    , p_rep_passenger_type
    , p_ship_id
    , p_room_class_id
    , p_applied_fare
  FROM
    target_sections AS ts
    CROSS JOIN generate_series(1, p_room_class_reserve_cnt) AS gs(id);

  ----------------------------------------
  -- 部屋と車両の予約
  ----------------------------------------
  -- 在庫テーブルの更新
  UPDATE ships.inventry AS i
  SET remaining_room_cnt = remaining_room_cnt - 1,
      remaining_num_of_people = remaining_num_of_people - p_room_class_reserve_cnt
  FROM
    target_sections AS ts
  WHERE 
    i.schedule_id = ts.schedule_id
    AND i.section_id = ts.section_id
    AND i.room_class_id = p_room_class_id
    AND i.remaining_room_cnt >= 1
  ;

  GET DIAGNOSTICS actual_upsert_count = ROW_COUNT;
  RAISE NOTICE '実際に更新されたレコード: %', actual_upsert_count;
  
  IF actual_upsert_count < upsert_count THEN
    RAISE EXCEPTION '部屋の在庫不足です（必要: %, 確保: %）', upsert_count, actual_upsert_count;
  END IF;

  -- 車両在庫テーブル
  UPDATE ships.vehicle_inventry AS i
  SET remaining_capacity = remaining_capacity - p_vehicle_reserve_cnt
  FROM
    target_sections AS ts
  WHERE 
    i.schedule_id = ts.schedule_id
    AND i.section_id = ts.section_id
    AND i.type_code = p_vehicle_type
    AND i.remaining_capacity >= p_vehicle_reserve_cnt
  ;

  GET DIAGNOSTICS actual_upsert_count = ROW_COUNT;
  RAISE NOTICE '実際に更新されたレコード: %', actual_upsert_count;

  IF actual_upsert_count < upsert_count THEN
    RAISE EXCEPTION '車両の在庫不足です（必要: %, 確保: %）', upsert_count, actual_upsert_count;
  END IF;

EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT
  RAISE EXCEPTION 'MESSAGE_TEXT %', error_message;

END;
$$;

-- プロシージャの呼び出し
CALL ships.insert_reservation(CAST('2026-01-23' AS DATE), 'P2', 'S001', 'R2', NULL, 'test_user_1', 'test@fuga.com', 'ADULT', 'TR', 2, 3000, 'CAR_REG', 1);
CALL ships.insert_reservation(CAST('2026-01-20' AS DATE), 'P3', 'S004', 'R3', NULL, 'test_user_2', 'abc@fuga.com', 'ADULT', 'DX', 3, 1800, 'MOT_CY_BIG', 3);
-- シーケンスのリセット
ALTER SEQUENCE ships.reservation_seq RESTART WITH 1;