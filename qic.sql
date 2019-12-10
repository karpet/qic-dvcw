-- SQLite schema for QIC project

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

create table cases (
  id varchar(16) primary key,
  case_worker_id varchar(16) not null references case_workers(id),
  survey_name varchar(16),
  surveyed_at datetime,
  created_at datetime,
  updated_at datetime
);
create index cases_case_worker_id_index on cases(case_worker_id);
create index cases_surveyed_at_index on cases(surveyed_at);

create table children (
  id varchar(32) primary key,
  client_id varchar(16),
  case_id varchar(16) not null references cases(id),
  first_name varchar(255),
  last_name varchar(255),
  dob date,
  created_at datetime,
  updated_at datetime
);
create index children_case_id_index on children(case_id);
create unique index children_client_id_case_id_index on children(client_id, case_id);

create table adults (
  id varchar(32) primary key,
  client_id varchar(16),
  case_id varchar(16) not null references cases(id),
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
  updated_at datetime
);
create index adults_case_id_index on adults(case_id);
create unique index adults_client_id_case_id_index on adults(client_id, case_id);

COMMIT;
