mv_stats  extension
======================================

The mv_stats extension is a means for tracking some statistics of all materialized views in a database.

The extension  must be loaded using the the PostgreSQL's clause `CREATE EXTENSION` 

When `mv_stat` is loaded, it begin to tracks statistics about  materialized views in this databases. 
To access and manipulate these statistics, the module provides a view named `mv_stats`, and the utility functions `mv_activity_init` and `mv_activity_reset_stats`. 



The statistics gathered by the module are made available via a view named mv_stats. 
This view contains one row for each distinct materialized view in the database, the columns of the view are shown in the following table.

| Column                |      Type     |  Description |
|-----------------------|---------------|--------------|
| mv_name               |  text         |  Name of MV schema-qualified|
| create_mv             |  timestamp    |  Timestamp of MV creation (`CREATE MATERIALIZED VIEW`), `NULL` means that MV existed before the extension and was loaded when creating the extension |
| mod_mv                |  timestamp    |  Timestamp of MV Modification (`ALTER MATERIALIZED VIEW`)  |
| refresh_mv_last       |  timestamp    |  Timestamp of last time that MV was refreshed (`REFRESH MATERIALIZED VIEW`)|
| refresh_count         |  int          |  Number of times refreshed |
| refresh_mv_time_last  |  interval     |  Duration of last refresh time |
| refresh_mv_time_total |  interval     |  Total refresh time  |
| refresh_mv_time_min   |  interval     |  Min refresh time  |
| refresh_mv_time_max   |  interval     |  Max refresh time  |
| reset_last            |  timestamp    |  Timestamp of last  stats reset  |



Install
--------
*Required PG10+ (tested)* 


Run: 
```
make install 
```

If not install,  you must make sure you can see the binary pg_config,
maybe setting PostgreSQL binary path in the OS  or setting PG_CONFIG = /path_to_pg_config/  in the makefile 
or run:  `make install  PG_CONFIG=/path_to_pg_config/`

In your database execute: 
```
CREATE EXTENSION mv_stats;
```

If you have some views created previously they will be automatically added to the stats on  blank, and after the refresh, stats will be fit

```

test=# SELECT mv_name,create_mv,mod_mv,refresh_mv_last as refresh_last, refresh_count, refresh_mv_time_last as refresh_time_last , refresh_mv_time_total as refresh_time_total, refresh_mv_time_min as refresh_time_min,refresh_mv_time_max  as refresh_time_max, reset_last FROM mv_stats ;
      mv_name      |         create_mv          | mod_mv |       refresh_last        | refresh_count | refresh_time_last | refresh_time_total | refresh_time_min | refresh_time_max | reset_last 
-------------------+----------------------------+--------+---------------------------+---------------+-------------------+--------------------+------------------+------------------+-------
 public.mv1        |                            |        |                           |             0 |                   | 00:00:00           |                  |                  | 

 

```



--Function:


`mv_activity_reset_stats (mview):` Reset the statistics collected, `mview` default value is `*`, means all MV, but can be define a specific MV passing the name of this view using the schema-qualified name, only for superuser


Example of use:
--------



Can check the statistics collected by the extension quering the view `mv_stats`:

```
test=# CREATE MATERIALIZED VIEW mv_example AS SELECT * FROM pg_stat_activity ;
test=# REFRESH MATERIALIZED VIEW mv_example ;
test=# SELECT mv_name,create_mv,mod_mv,refresh_mv_last as refresh_last, refresh_count, refresh_mv_time_last as refresh_time_last , refresh_mv_time_total as refresh_time_total, refresh_mv_time_min as refresh_time_min,refresh_mv_time_max  as refresh_time_max, reset_last FROM mv_stats ;
      mv_name      |         create_mv          | mod_mv |       refresh_last        | refresh_count | refresh_time_last | refresh_time_total | refresh_time_min | refresh_time_max | reset_last 
-------------------+----------------------------+--------+---------------------------+---------------+-------------------+--------------------+------------------+------------------+-------
 public.mv_example | 2021-02-03 15:32:35.826251 |        | 2021-02-03 15:32:45.37572 |             1 | 00:00:00.45811    | 00:00:00.45811     | 00:00:00.45811   | 00:00:00.45811   | 
(1 row)



```


To reset the statistic collected you can use the function   `mv_activity_reset_stats`
```
-- for specific MV
test=# SELECT * FROM mv_activity_reset_stats ('public.mv_example');
 mv_activity_reset_stats 
-------------------------
 public.mv_example
(1 row)


test=# SELECT mv_name,create_mv,mod_mv,refresh_mv_last as refresh_last, refresh_count, refresh_mv_time_last as refresh_time_last , refresh_mv_time_total as refresh_time_total, refresh_mv_time_min as refresh_time_min,refresh_mv_time_max  as refresh_time_max, reset_last FROM mv_stats ;
      mv_name      |         create_mv          | mod_mv | refresh_last | refresh_count | refresh_time_last | refresh_time_total | refresh_time_min | refresh_time_max |         reset_last         
-------------------+----------------------------+--------+--------------+---------------+-------------------+--------------------+------------------+------------------+-----------------
 public.mv1        |                            |        |              |             0 |                   | 00:00:00           |                  |                  | 
 public.mv_example | 2021-02-03 15:32:35.826251 |        |              |             0 |                   | 00:00:00           |                  |                  | 2021-02-03 15:38:37.540717
(2 rows)


-- for all views 
test=# SELECT * FROM mv_activity_reset_stats ();
 mv_activity_reset_stats 
-------------------------
 public.mv_example
 public.mv1
(2 rows)

```

The "extension" can be used in a PostgreSQL installation where you can not install extra extension (such us RDS, etc), you just must load the script mv_stats--0.1.0.sql in your database and enjoy it, to “remove the extension" in this case you can use the function select _mv_drop_objects();



IMPORTANT: If you find some bugs in the existing version, please contact to me.

Anthony R. Sotolongo León

asotolongo@ongres.com

asotolongo@gmail.com

