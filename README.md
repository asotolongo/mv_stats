mv_stats  extension
======================================

The mv_stats extension a means for tracking some statistics of all materialized views in a database.

The extension  must be loaded using the the PostgreSQL's clause `CREATE EXTENSION` 

When `mv_stat` is loaded, it begin to tracks statistics about  materialized views in this databases. 
To access and manipulate these statistics, the module provides a view named `mv_stats`, and the utility functions `mv_activity_init` and `mv_activity_reset_stats`. 



The statistics gathered by the module are made available via a view named mv_stats. 
This view contains one row for each distinct materialized view in  database,  The columns of the view are shown in following Table.

| Colunm                |      Type     |  Description |
|-----------------------|---------------|--------------|
| mv_name               |  text         |  Name of MV schema-qualified|
| create_mv             |  timestamp    |  Timestamp of MV creation (`CREATE MATERIALIZED VIEW`), `NULL` means that MV existed before the extension and was loaded using the function `mv_activity_init` |
| mod_mv                |  timestamp    |  Timestamp of MV Modification (`ALTER MATERIALIZED VIEW`)  |
| refresh_mv_last       |  timestamp    |  Timestamp of last time that MV was refreshed (`REFRESH MATERIALIZED VIEW`)|
| refresh_count         |  int          |   Number of times refreshed |
| refresh_mv_time_last  |  interval     |   Refresh time of last time |
| refresh_mv_time_total |  interval     |   Total refresh time  |



Install
--------
*Required PG10+ (tested)* 


Run: 
```
make install 
```

If not install,  you must make sure you can see the binary pg_config,
maybe setting PostgreSQL binary path in the OS  or setting PG_CONFIG = /path_to_pg_config/  in the makefile 
or run:  `make install  PG_CONFIG = /path_to_pg_config/`

In your database execute: 
```
CREATE EXTENSION mv_stats;
```





--Functions:

`mv_activity_init():` Add the views that was created previously to the extension and begin to track statistics( `create_mv` column is marked NULL)

`mv_activity_reset_stats (mview):` Reset the statistics collected, `mview` default value is `*`, means all MV, but can be define a specific MV passing the name of this view using schema-qualified name


Example of use:
--------



Can check the statistics collected by the extension quering the view `mv_stats`:

```
test=# CREATE MATERIALIZED VIEW mv_example AS SELECT * FROM pg_stat_activity ;
test=# REFRESH MATERIALIZED VIEW mv_example ;
test=# SELECT * FROM mv_stats ;
      mv_name      |         create_mv          | mod_mv |      refresh_mv_last       | refresh_count | refresh_mv_time_last | refresh_mv_time_total 
-------------------+----------------------------+--------+----------------------------+---------------+----------------------+-----------------------
 public.mv_example | 2021-01-31 13:20:21.293996 |        | 2021-01-31 13:21:33.490651 |             1 | 00:00:00.689449      | 00:00:00.689449
(1 row)



```

If have MVs previous of create the extension, these MVs can be adde to extension using the function `mv_activity_init`
```
test=# SELECT * FROM mv_activity_init();
 mv_activity_init 
------------------
 public.mv1
(1 row)

test=# SELECT * FROM mv_stats ;
      mv_name      |         create_mv          | mod_mv |      refresh_mv_last       | refresh_count | refresh_mv_time_last | refresh_mv_time_total 
-------------------+----------------------------+--------+----------------------------+---------------+----------------------+-----------------------
 public.mv_example | 2021-01-31 13:20:21.293996 |        | 2021-01-31 13:21:33.490651 |             1 | 00:00:00.689449      | 00:00:00.689449
 public.mv1        |                            |        |                            |             0 |                      | 00:00:00
(2 rows)
 

```

To reset the statistic collected can use the function   `mv_activity_reset_stats`
```
-- for specific MV
test=# SELECT * FROM mv_activity_reset_stats ('public.mv_example');
 mv_activity_reset_stats 
-------------------------
 public.mv_example
(1 row)


test=# SELECT * FROM mv_stats ;
      mv_name      |         create_mv          | mod_mv | refresh_mv_last | refresh_count | refresh_mv_time_last | refresh_mv_time_total 
-------------------+----------------------------+--------+-----------------+---------------+----------------------+-----------------------
 public.mv1        |                            |        |                 |             0 |                      | 00:00:00
 public.mv_example | 2021-01-31 13:20:21.293996 |        |                 |             0 |                      | 00:00:00
(2 rows)

-- for all views 
test=# SELECT * FROM mv_activity_reset_stats ();
 mv_activity_reset_stats 
-------------------------
 public.mv_example
 public.mv1
(2 rows)

```




IMPORTANT: If you find some bugs in the existing version, please contact to me.

Anthony R. Sotolongo León
asotolongo@gmail.com

