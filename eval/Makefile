db-reset:
	rm afcars.db && sqlite3 afcars.db < afcars.sql

build:
	perl ../bin/load-afcars-db.pl ../2022-evaluation/Administrative*/Illinois/normalized/*csv
	perl ../bin/load-afcars-db.pl ../2022-evaluation/Administrative*/Massachusetts/AFCARS/normalized/*csv

norm: norm-mass norm-ill

norm-mass:
	perl ../bin/mass/afcars-norm.pl ../2022-evaluation/Administrative*/Massachusetts/AFCARS/*json
	mv ../2022-evaluation/Administrative*/Massachusetts/AFCARS/*-norm.csv ../2022-evaluation/Administrative*/Massachusetts/AFCARS/normalized/

norm-ill:
	perl ../bin/illinois/afcars-norm.pl ../2022-evaluation/Administrative*/Illinois/*json
	mv ../2022-evaluation/Administrative*/Illinois/*-norm.csv ../2022-evaluation/Administrative*/Illinois/normalized/


.PHONY: db-reset build norm norm-ill norm-mass
