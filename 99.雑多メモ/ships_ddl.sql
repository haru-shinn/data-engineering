/*
船の予約管理用のDDL

データベース：postgreSQL
*/

CREATE DATABASE WORK_DB;
CREATE SCHEMA SHIPS;

CREATE TABLE passengers (
    passenger_id char(8) Primary Key
    , passenger_name varchar(256) NOT NULL
    , birth_date date
    , gender char(1)
    , email varchar(256)
);

CREATE TABLE ships (
    ship_id char(4) Primary Key
    , ship_name varchar(16) NOT NULL
    , length float NOT NULL
    , gross_tonnage integer NOT NULL
    , start_date date NOT NULL
    , end_date date
);

CREATE TABLE rooms (
    room_id char(4) PRIMARY KEY
    , ship_id char(4) PRIMARY KEY
    , room_class char(2)
    , room_count integer CONSTRAINT positive_count CHECK (room_count > 0)
);

CREATE TABLE routes (
    route_id char(3) PRIMARY KEY
    , departure_port_id char(2) REFERENCES ports(port_id)
    , arrival_port_id char(2) REFERENCES ports(port_id)
    , route_order integer CONSTRAINT positive_number CHECK (room_count > 0)
);

CREATE TABLE ports (
    port_id char(2) PRIMARY KEY
    , port_name varchar(128)
    , prefecture_code char(2) REFERENCES prefectures(prefecture_code)
    , city_code char(3) REFERENCES cities(city_code)
    , address varchar(256)
);

CREATE TABLE prefectures (
    prefecture_code char(2) PRIMARY KEY
    , prefecture_name varchar(16)
);

CREATE TABLE cities (
    city_code char(3) PRIMARY KEY
    , prefecture_code char(2) REFERENCES prefectures(prefecture_code)
    , city_name varchar(16)
);

CREATE TABLE schedule (
    schedule_id char(4) PRIMARY KEY
    , route_id char(3) REFERENCES routes(route_id)
    , ship_id char(4) REFERENCES ships(ship_id)
    , departure_date date
);

CREATE TABLE reservations (
    reservation_id char(8) PRIMARY KEY
    , passenger_id char(8) REFERENCES passengers(passenger_id)
    , schedule_id char(4) REFERENCES schedule(schedule_id)
    , reservation_date date
);

CREATE TABLE ticketing (
    ticket_id char(8) PRIMARY KEY
    , reservation_id char(8) REFERENCES reservations(reservation_id)
    , ticket_type char(2)
);

CREATE TABLE boarding (
    boarding_id char(8) PRIMARY KEY
    , reservation_id char(8) REFERENCES reservations(reservation_id)
    , boarding_flg boolean
);

CREATE TABLE fare_master (
    room_class char(2)
    , route_id char(3) REFERENCES routes(route_id)
    , fare integer
    , PRIMARY KEY (room_class, route_id)
);