db-reset:
	rm afcars.db && sqlite3 afcars.db < afcars.sql

build:
	perl ../bin/load-afcars-db.pl ../2022-evaluation/Administrative*/Illinois/normalized/*csv
	perl ../bin/load-afcars-db.pl ../2022-evaluation/Administrative*/Massachusetts/AFCARS/normalized/*csv

norm: norm-mass norm-ill

norm-mass:
	perl ../bin/mass/afcars-norm.pl ../2022-evaluation/Administrative*/Massachusetts/AFCARS/*json

norm-ill:
	perl ../bin/illinois/afcars-norm.pl ../2022-evaluation/Administrative*/Illinois/*json


.PHONY: db-reset build norm norm-ill norm-mass
