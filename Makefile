EXTENSION = mv_stats
DATA = mv_stats--0.2.0.sql
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

