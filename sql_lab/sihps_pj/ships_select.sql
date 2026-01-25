- １区間用
SELECT
  ship_name
  , departure_time
  , arrival_time
  , departure_port
  , arrival_port
  , room_class_name
  , remaining_room_cnt
  , room_count
  , room_vacancy_rate
  , mot_cy_big_rem -- すべて記載すると数が多いので、画面上から選択された乗り物だけを示すものとする。
FROM
  ships.availability_v
WHERE
  CAST(departure_date AS VARCHAR) BETWEEN '2026-01-20' AND CAST(CAST('2026-01-20' AS DATE) + (CAST('3 days' AS INTERVAL)) AS VARCHAR)
  AND departure_port = '横須賀港'
  AND room_class_name NOT IN ('ドライバー室', 'スイート', 'デラックス')
;

-- 2区間用
WITH tmp AS (
  SELECT
    schedule_id
    , ship_name
    , section_id
    , CASE section_id
        WHEN 'S1' THEN 'South'
        WHEN 'S2' THEN 'North'
        WHEN 'S3' THEN 'North'
        WHEN 'S4' THEN 'South'
      END AS direction
    , departure_date
    , departure_time
    , arrival_date
    , arrival_time
    , departure_port
    , arrival_port
    , room_class_name
    , remaining_room_cnt
    , room_count
    , room_vacancy_rate
    , mot_cy_big_rem
  FROM
    ships.availability_v
  WHERE
    CAST(departure_date AS VARCHAR) 
      BETWEEN '2026-01-20' AND CAST(CAST('2026-01-20' AS DATE) + (CAST('10 days' AS INTERVAL)) AS VARCHAR)
    AND route_id = 'R3'
    AND ship_name = 'GrapeMaru'
    AND (departure_port = '新門司港' OR arrival_port = '苫小牧港')
    AND room_class_name NOT IN ('ドライバー室', 'スイート', 'デラックス', 'ツーリング（寝台）')
)
SELECT
  ship_name
  , departure_time
  , arrival_time
  , departure_port
  , arrival_port
  , room_class_name
  , remaining_room_cnt
  , room_count
  , room_vacancy_rate
  , MIN(mot_cy_big_rem) 
      OVER(PARTITION BY ship_name, room_class_name, direction, 
            (departure_date - (CASE WHEN section_id IN ('S3', 'S1') THEN 1 ELSE 0 END))
      ) AS car_reg_rem
  , mot_cy_big_rem
FROM
  tmp
ORDER BY
  ship_name
  , departure_time
;
