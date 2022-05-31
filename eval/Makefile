a-db-reset:
	rm afcars.db && sqlite3 afcars.db < afcars.sql

a-build:
	perl ../bin/load-afcars-db.pl ../2022-evaluation/Administrative*/Illinois/normalized/AFCARS*csv
	perl ../bin/load-afcars-db.pl ../2022-evaluation/Administrative*/Massachusetts/AFCARS/normalized/*csv
	perl ../bin/load-afcars-db.pl ../2022-evaluation/penn-afcars-norm.csv

a-norm: a-norm-mass a-norm-ill

a-norm-mass:
	rm -rf ./2022-evaluation/Administrative*/Massachusetts/AFCARS/normalized/*csv
	perl ../bin/mass/afcars-norm.pl ../2022-evaluation/Administrative*/Massachusetts/AFCARS/*json
	mv ../2022-evaluation/Administrative*/Massachusetts/AFCARS/*-norm.csv ../2022-evaluation/Administrative*/Massachusetts/AFCARS/normalized/

a-norm-ill:
	rm -rf ../2022-evaluation/Administrative*/Illinois/normalized/AFCARS*-norm.csv
	perl ../bin/illinois/afcars-norm.pl ../2022-evaluation/Administrative*/Illinois/AFCARS*json
	mv ../2022-evaluation/Administrative*/Illinois/*-norm.csv ../2022-evaluation/Administrative*/Illinois/normalized/

n-norm-mass:
	perl ../bin/mass/ncands-norm.pl ../2022-evaluation/Administrative*/Massachusetts/Intakes*/NCANDS*json
	mv ../2022-evaluation/Administrative*/Massachusetts/Intakes*/*-norm.csv ../2022-evaluation/Administrative*/Massachusetts/Intakes*/normalized/

n-norm-ill:
	perl ../bin/illinois/ncands-norm.pl ../2022-evaluation/Administrative*/Illinois/NCANDS*json
	mv ../2022-evaluation/Administrative*/Illinois/NCANDS*-norm.csv ../2022-evaluation/Administrative*/Illinois/normalized/

n-norm: n-norm-mass n-norm-ill

n-db-reset:
	rm ncands.db && sqlite3 ncands.db < ncands.sql

n-build:
	perl ../bin/load-ncands-db.pl ../2022-evaluation/Administrative*/Illinois/normalized/NCANDS*csv
	perl ../bin/load-ncands-db.pl ../2022-evaluation/Administrative*/Massachusetts/Intakes*/normalized/*csv

d3-norm-mass:
	perl ../bin/mass/d3-norm.pl ../2022-evaluation/Administrative*/Massachusetts/DV*/*json
	mv ../2022-evaluation/Administrative*/Massachusetts/DV*/*-norm.csv ../2022-evaluation/Administrative*/Massachusetts/DV*/normalized/

d5-norm-mass:
	perl ../bin/mass/d5-norm.pl ../2022-evaluation/Administrative*/Massachusetts/Worker*/*json
	mv ../2022-evaluation/Administrative*/Massachusetts/Worker*/*-norm.csv ../2022-evaluation/Administrative*/Massachusetts/Worker*/normalized/

d5-norm-ill:
	perl ../bin/illinois/d5-norm.pl ../2022-evaluation/Administrative*/Illinois/DV-*json
	mv ../2022-evaluation/Administrative*/Illinois/DV-*-norm.csv ../2022-evaluation/Administrative*/Illinois/normalized/

ds-db-reset:
	rm datasets.db && sqlite3 datasets.db < datasets.sql

ds-build:
	perl ../bin/mass/load-d5-db.pl ../2022-evaluation/Administrative*/Massachusetts/Worker*/normalized/*csv
	perl ../bin/illinois/load-d5-db.pl ../2022-evaluation/Administrative*/Illinois/normalized/DV-*csv


.PHONY: a-db-reset a-build a-norm a-norm-ill a-norm-mass n-norm-mass n-norm-ill n-db-reset n-build
