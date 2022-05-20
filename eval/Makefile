a-db-reset:
	rm afcars.db && sqlite3 afcars.db < afcars.sql

a-build:
	perl ../bin/load-afcars-db.pl ../2022-evaluation/Administrative*/Illinois/normalized/AFCARS*csv
	perl ../bin/load-afcars-db.pl ../2022-evaluation/Administrative*/Massachusetts/AFCARS/normalized/*csv

a-norm: norm-mass norm-ill

a-norm-mass:
	perl ../bin/mass/afcars-norm.pl ../2022-evaluation/Administrative*/Massachusetts/AFCARS/*json
	mv ../2022-evaluation/Administrative*/Massachusetts/AFCARS/*-norm.csv ../2022-evaluation/Administrative*/Massachusetts/AFCARS/normalized/

a-norm-ill:
	perl ../bin/illinois/afcars-norm.pl ../2022-evaluation/Administrative*/Illinois/*json
	mv ../2022-evaluation/Administrative*/Illinois/*-norm.csv ../2022-evaluation/Administrative*/Illinois/normalized/

n-norm-mass:
	perl ../bin/mass/ncands-norm.pl ../2022-evaluation/Administrative*/Massachusetts/Intakes*/NCANDS*json
	mv ../2022-evaluation/Administrative*/Massachusetts/Intakes*/*-norm.csv ../2022-evaluation/Administrative*/Massachusetts/Intakes*/normalized/

n-norm-ill:
	perl ../bin/illinois/ncands-norm.pl ../2022-evaluation/Administrative*/Illinois/NCANDS*json
	mv ../2022-evaluation/Administrative*/Illinois/NCANDS*-norm.csv ../2022-evaluation/Administrative*/Illinois/normalized/

n-db-reset:
	rm ncands.db && sqlite3 ncands.db < ncands.sql

n-build:
	perl ../bin/load-ncands-db.pl ../2022-evaluation/Administrative*/Illinois/normalized/NCANDS*csv
	perl ../bin/load-ncands-db.pl ../2022-evaluation/Administrative*/Massachusetts/Intakes*/normalized/*csv


.PHONY: a-db-reset a-build a-norm a-norm-ill a-norm-mass n-norm-mass n-norm-ill n-db-reset n-build
