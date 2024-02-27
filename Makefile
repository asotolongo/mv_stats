EXTENSION = mv_stats
DATA = mv_stats--0.2.0.sql mv_stats--0.2.0--0.3.0.sql

TESTS        = $(wildcard test/sql/*.sql)
REGRESS      = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = --inputdir=test --temp-instance=/tmp/tmp_check  

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

