/*
船の予約管理用のDDL

データベース：postgreSQL
*/

CREATE DATABASE WORK_DB;
CREATE SCHEMA SHIPS;

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

-- 船マスタ（基本情報）
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

-- 車両区分マスタ（普通車、軽自動車、長さによる区分など）
DROP TABLE IF EXISTS SHIPS.VEHICLE_TYPES CASCADE;
CREATE TABLE SHIPS.VEHICLE_TYPES (
    type_code VARCHAR(16) PRIMARY KEY -- 'CAR_REG', 'CAR_SMALL', 'TRUCK_L' など
    , type_name VARCHAR(32) NOT NULL  -- '普通車', '軽自動車'
    , length_limit DECIMAL(4, 2)        -- 車は長さで判定（5.0mまでなど）
    , displacement_limit INTEGER        -- 二輪車は排気量で判定（50cc以下など）
);

-- 船別積載能力
DROP TABLE IF EXISTS SHIPS.SHIP_CAPACITIES CASCADE;
CREATE TABLE SHIPS.SHIP_CAPACITIES (
    ship_id CHAR(4) NOT NULL
    , type_code VARCHAR(12) NOT NULL
    , max_capacity INTEGER NOT NULL
    , PRIMARY KEY (ship_id, type_code)
    , FOREIGN KEY (ship_id) REFERENCES SHIPS.SHIPS(ship_id)
    , FOREIGN KEY (type_code) REFERENCES SHIPS.VEHICLE_TYPES(type_code)
);

-- 客室クラス定義マスタ
DROP TABLE IF EXISTS SHIPS.ROOM_CLASS_MASTER CASCADE;
CREATE TABLE IF NOT EXISTS SHIPS.ROOM_CLASS_MASTER (
    room_class_id CHAR(2)
    , room_class_name VARCHAR(16)
    , capacity_per_room INTEGER
    , notice VARCHAR(256)
    , PRIMARY KEY (room_class_id)
    , UNIQUE (room_class_id, capacity_per_room)
);

-- 船別客室設定
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

-- 客室マスタ
DROP TABLE IF EXISTS SHIPS.ROOMS CASCADE;
CREATE TABLE IF NOT EXISTS SHIPS.ROOMS (
    room_id CHAR(9)          -- 船ID(4桁) + クラスID(2桁) + 連番(3桁)
    , ship_id CHAR(4)
    , room_class_id CHAR(2)
    , room_no CHAR(3)        -- 連番
    , PRIMARY KEY (room_id)
    , FOREIGN KEY (ship_id, room_class_id) REFERENCES ships.ship_room_classes(ship_id, room_class_id)
);

DROP TABLE IF EXISTS SHIPS.ROUTES;
CREATE TABLE IF NOT EXISTS SHIPS.ROUTES (
    route_id CHAR(3) PRIMARY KEY
    , departure_port_id CHAR(2) REFERENCES ships.ports(port_id)
    , arrival_port_id CHAR(2) REFERENCES ships.ports(port_id)
);

DROP TABLE IF EXISTS SHIPS.SECTIONS;
CREATE TABLE IF NOT EXISTS SHIPS.SECTIONS (
    section_id CHAR(2) PRIMARY KEY
    , departure_port_id CHAR(2) REFERENCES ships.ports(port_id)
    , arrival_port_id CHAR(2) REFERENCES ships.ports(port_id)
    , standard_time_required CHAR(8)
    , notice CHAR(256)
);

DROP TABLE IF EXISTS SHIPS.ROUTE_SECTIONS;
CREATE TABLE IF NOT EXISTS SHIPS.ROUTE_SECTIONS (
    section_id CHAR(2) REFERENCES ships.sections(section_id)
    , route_id CHAR(2) REFERENCES ships.routes(route_id)
    , PRIMARY KEY (section_id, route_id)
);

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

DROP TABLE IF EXISTS SHIPS.SCHEDULE;
CREATE TABLE IF NOT EXISTS SHIPS.SCHEDULE (
    schedule_id CHAR(12) PRIMARY KEY
    , route_id CHAR(2) REFERENCES ships.routes(route_id)
    , section_id CHAR(2) REFERENCES ships.sections(section_id)
    , departure_date DATE
    , arrival_date DATE
    , departure_time timestamp
    , arrival_time timestamp
    , ship_id CHAR(4) REFERENCES ships.ships(ship_id)
);

DROP TABLE IF EXISTS SHIPS.RESERVATIONS;
CREATE TABLE IF NOT EXISTS SHIPS.RESERVATIONS (
    reservation_id CHAR(8) PRIMARY KEY
    , passenger_id CHAR(8)
    , schedule_id CHAR(12) REFERENCES ships.schedule(schedule_id)
    , rep_name CHAR(256)
    , rep_email CHAR(256)
    , reservation_date DATE
);

DROP TABLE IF EXISTS SHIPS.RESERVATION_DETAILS;
CREATE TABLE IF NOT EXISTS SHIPS.RESERVATION_DETAILS (
    reservation_id CHAR(8) REFERENCES ships.reservations(reservation_id)
    , detail_id CHAR(3)
    , passenger_id CHAR(8)
    , passenger_type CHAR(8)
    , ship_id CHAR(4) REFERENCES ships.ships(ship_id)
    , room_class_id CHAR(2)
    , applied_fare INTEGER
    , PRIMARY KEY (reservation_id, detail_id)
    , FOREIGN KEY (ship_id, room_class_id) REFERENCES SHIPS.ROOM_CLASS(ship_id, room_class_id)
);

DROP TABLE IF EXISTS SHIPS.INVENTRY;
CREATE TABLE IF NOT EXISTS SHIPS.INVENTRY (
    route_id CHAR(3) REFERENCES ships.routes(route_id)
    , section_id CHAR(2) REFERENCES ships.sections(section_id)
    , departure_date DATE
    , departure_time TIMESTAMP
    , ship_id CHAR(4) REFERENCES ships.ships(ship_id)
    , room_class_id CHAR(2)
    , room_count INTEGER
    , remaining_room_cnt INTEGER
    , num_of_people INTEGER
    , remaining_num_of_people INTEGER
    , PRIMARY KEY (ship_id, section_id, room_class_id, departure_time)
    , FOREIGN KEY (ship_id, room_class_id) REFERENCES SHIPS.ROOM_CLASS(ship_id, room_class_id)
);

DROP TABLE IF EXISTS SHIPS.TICKETING;
CREATE TABLE IF NOT EXISTS SHIPS.TICKETING (
    ticket_id CHAR(8) PRIMARY KEY
    , reservation_id CHAR(8) REFERENCES ships.reservations(reservation_id)
    , ticket_type CHAR(2)
);

DROP TABLE IF EXISTS SHIPS.BOARDING;
CREATE TABLE IF NOT EXISTS SHIPS.BOARDING (
    boarding_id CHAR(8) PRIMARY KEY
    , reservation_id CHAR(8) REFERENCES ships.reservations(reservation_id)
    , boarding_flg boolean
);

DROP TABLE IF EXISTS SHIPS.FARE_MASTER;
CREATE TABLE IF NOT EXISTS SHIPS.FARE_MASTER (
    room_class CHAR(2)
    , route_id CHAR(3) REFERENCES ships.routes(route_id)
    , ship_id CHAR(4) REFERENCES ships.ships(ship_id)
    , fare INTEGER
    , PRIMARY KEY (room_class, route_id)
);