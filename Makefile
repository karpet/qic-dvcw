deps:
	installdeps -ruRX bin lib

sql:
	sqlite3 qic.db

prod:
	sqlite3 qic-prod.db

dev:
	sqlite3 qic-dev.db

db:
	perl -Ilib -e 'use QIC::DB'

c:
	perl bin/console

dump:
	sqlite3 qic-prod.db .dump | gzip -c > qic-`date +%Y%m%d-%H%M%S`-dump.sql.gz

backup:
	cp qic-prod.db qic-`date +%Y%m%d-%H%M%S`-prod.db

allegheny-emails:
	csv2json AC\ Master\ Dataset\ 12.01.19.csv | jpretty | jq '[ .[] | { first_name: ."First Name", last_name: ."Last Name", email: ."Email Address" }]' > ac-master-dataset-20191201.json

.PHONY: deps
