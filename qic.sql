-- SQLite schema for QIC project

PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

create table case_workers (
  id varchar(16) primary key,
  first_name varchar(255),
  last_name varchar(255),
  email varchar(255),
  site_name varchar(255),
  site_office_name varchar(255),
  created_at datetime,
  updated_at datetime
);
create unique index case_workers_email_index on case_workers(email);
create unique index case_workers_id_site_index on case_workers(id, site_name);

create table cases (
  id varchar(16) primary key,
  case_worker_id varchar(16) not null,
  survey_name varchar(16),
  surveyed_at datetime,
  replaced_at datetime,
  closed_at datetime,
  created_at datetime,
  updated_at datetime,
  foreign key (case_worker_id) references case_workers(id) on delete cascade
);
create index cases_case_worker_id_index on cases(case_worker_id);
create index cases_surveyed_at_index on cases(surveyed_at);
create index cases_replaced_at_index on cases(replaced_at);
create index cases_closed_at_index on cases(closed_at);
create unique index cases_uniq_per_worker_index on cases(id, case_worker_id);

create table children (
  id varchar(32) primary key,
  client_id varchar(32),
  case_id varchar(16) not null,
  first_name varchar(255),
  last_name varchar(255),
  dob date,
  created_at datetime,
  updated_at datetime,
  foreign key (case_id) references cases(id) on delete cascade
);
create index children_case_id_index on children(case_id);
create unique index children_client_id_case_id_index on children(client_id, case_id);

create table adults (
  id varchar(32) primary key,
  client_id varchar(32),
  case_id varchar(16) not null,
  first_name varchar(255),
  last_name varchar(255),
  dob date,
  address_one varchar(255),
  address_two varchar(255),
  city varchar(255),
  state varchar(255),
  zipcode varchar(255),
  email varchar(255),
  sex varchar(32),
  role varchar(32),
  home_phone varchar(32),
  work_phone varchar(32),
  mobile_phone varchar(32),
  created_at datetime,
  updated_at datetime,
  foreign key (case_id) references cases(id) on delete cascade
);
create index adults_case_id_index on adults(case_id);
create unique index adults_client_id_case_id_index on adults(client_id, case_id);

COMMIT;
