db-reset:
	rm afcars.db && sqlite3 afcars.db < afcars.sql

build:
	perl ../bin/load-afcars-db.pl ../2022-evaluation/Administrative*/Illinois/normalized/*csv
	perl ../bin/load-afcars-db.pl ../2022-evaluation/Administrative*/Massachusetts/AFCARS/normalized/*csv


.PHONY: db-reset build
