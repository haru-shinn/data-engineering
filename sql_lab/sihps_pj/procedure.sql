/* プロシージャ */

/* ======================================== */
/* 予約データ挿入用のプロシージャ */
DROP PROCEDURE IF EXISTS ships.insert_reservation
(DATE, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, INTEGER, TEXT, INTEGER);

CREATE OR REPLACE PROCEDURE ships.insert_reservation (
  p_departure_date DATE DEFAULT NULL
  , p_departure_port_id TEXT DEFAULT NULL
  , p_ship_id TEXT DEFAULT NULL
  , p_route_id TEXT DEFAULT NULL
  , p_section_id TEXT DEFAULT NULL
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
  p_schedule_id TEXT;
  p_current_date DATE;
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
  SELECT s.schedule_id INTO p_schedule_id FROM ships.schedule AS s 
  WHERE s.route_id = p_route_id 
    AND s.section_id = p_section_id 
    AND s.departure_date = p_departure_date 
    AND s.ship_id = p_ship_id;

  SELECT CURRENT_DATE INTO  p_current_date;

  ----------------------------------------
  -- 部屋予約
  ----------------------------------------
  -- 予約基本情報テーブルへの挿入
  INSERT INTO ships.reservations (reservation_id, rep_name, rep_email, reservation_date, vehicle_type_code) 
  VALUES ('20260110-001', p_rep_name, p_rep_email, p_current_date, p_vehicle_type);

 -- 予約明細情報テーブルへの挿入
  INSERT INTO ships.reservation_details (reservation_id, detail_id, section_id, schedule_id, passenger_type, ship_id, room_class_id, applied_fare) VALUES 
  ('20260110-001', '001', p_section_id, p_schedule_id, p_rep_passenger_type, p_ship_id, p_room_class_id, p_applied_fare),
  ('20260110-001', '002', p_section_id, p_schedule_id, p_rep_passenger_type, p_ship_id, p_room_class_id, p_applied_fare)
  ;

  ----------------------------------------
  -- 部屋と車両の予約
  ----------------------------------------
  -- 在庫テーブルの更新
  UPDATE ships.inventry
  SET remaining_room_cnt = remaining_room_cnt - 1,
      remaining_num_of_people = remaining_num_of_people - 2
  WHERE 
    schedule_id = p_schedule_id
    AND section_id = p_section_id
    AND room_class_id = p_room_class_id
    AND remaining_room_cnt >= 1
  ;

  -- 車両在庫テーブル
  UPDATE ships.vehicle_inventry
  SET remaining_capacity = remaining_capacity - 1
  WHERE 
    schedule_id = p_schedule_id
    AND section_id = p_section_id
    AND type_code = p_vehicle_type
    AND remaining_capacity >= 1
  ;

END;
$$;

-- プロシージャの呼び出し
CALL ships.insert_reservation(CAST('2026-01-23' AS DATE), 'p2', 'S001', 'R2', 'S3', NULL, 'test_user_1', 'test@fuga.com', 'ADULT', 'TR', 2, 3000, 'CAR_REG', 1);

