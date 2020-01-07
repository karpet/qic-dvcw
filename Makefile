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
	sqlite3 qic-prod.db .dump | gzip -c > data/backups/qic-`date +%Y%m%d-%H%M%S`-dump.sql.gz

backup:
	cp qic-prod.db data/backups/qic-`date +%Y%m%d-%H%M%S`-prod.db

.PHONY: deps
