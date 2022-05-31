-- SQLite schema for QIC project

PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

create table ds5 (
  id integer primary key,
  state char(2) not null,
  child_state_id varchar(64) not null, -- e.g. QIC Person ID
  case_id varchar(64), -- e.g. QIC Case ID
  month char(7) not null,
  in_person_visits integer not null default 0,
  video_visits integer not null default 0,
  afcars_id varchar(32),
  ncands_id varchar(32)
);

create index ds5_child_state_id_idx on ds5(child_state_id);
create index ds5_case_id_idx on ds5(case_id);
create index ds5_state_idx on ds5(state);
create index ds5_afcars_id_idx on ds5(afcars_id);
create index ds5_ncands_id_idx on ds5(ncands_id);

COMMIT;
