CREATE  TABLE _mv_stats ( mv_name text ,create_mv timestamp, mod_mv timestamp, refresh_mv_last timestamp , refresh_count int default 0,
refresh_mv_time_last interval, refresh_mv_time_total interval default '00:00:00', refresh_mv_time_min interval, refresh_mv_time_max interval, reset_last timestamp);
CREATE  VIEW  mv_stats as select * from _mv_stats;


CREATE OR REPLACE FUNCTION fn_trg_mv()  RETURNS event_trigger AS
$$

DECLARE
  r RECORD;
  flag boolean;
  t_refresh_total interval;

BEGIN

  FOR r IN SELECT * FROM pg_event_trigger_ddl_commands() 

    LOOP
      IF tg_tag = 'CREATE MATERIALIZED VIEW' THEN 
       INSERT INTO _mv_stats (mv_name , create_mv ) VALUES ( r.object_identity,now());
      END IF;
      IF tg_tag = 'ALTER MATERIALIZED VIEW' THEN 
        SELECT TRUE INTO flag from _mv_stats where mv_name=r.object_identity;
        IF NOT FOUND THEN 
          INSERT INTO _mv_stats (mv_name , create_mv ) VALUES ( r.object_identity,now());
          DELETE FROM _mv_stats WHERE mv_name NOT IN (SELECT schemaname||'.'||matviewname FROM pg_catalog.pg_matviews);
        ELSE 
          UPDATE  _mv_stats SET mod_mv=now() WHERE mv_name= r.object_identity;
        END IF;
      END IF;
      IF tg_tag = 'REFRESH MATERIALIZED VIEW' THEN 
       t_refresh_total:=clock_timestamp()-(select current_setting ('mv_stats.start')::timestamp);
       SET mv_stats.start to default;
       UPDATE  _mv_stats SET refresh_mv_last=now(),refresh_count=refresh_count+1,refresh_mv_time_last=t_refresh_total, refresh_mv_time_total=refresh_mv_time_total+t_refresh_total,
        refresh_mv_time_min = (CASE WHEN refresh_mv_time_min IS NULL THEN t_refresh_total
                                    WHEN refresh_mv_time_min IS NOT NULL AND refresh_mv_time_min > t_refresh_total THEN t_refresh_total
                                    ELSE  refresh_mv_time_min
                                    END),
        refresh_mv_time_max = (CASE WHEN refresh_mv_time_max IS NULL THEN t_refresh_total
                                    WHEN refresh_mv_time_max IS NOT NULL AND refresh_mv_time_max < t_refresh_total THEN t_refresh_total
                                    ELSE  refresh_mv_time_max
                                    END)                           
        WHERE mv_name= r.object_identity;
      END if;
     
    END LOOP;

END;

$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_trg_mv_drop()  RETURNS event_trigger AS
$$

DECLARE
  r RECORD;
  flag boolean; 

BEGIN
  FOR r IN SELECT * FROM pg_event_trigger_dropped_objects()
    LOOP
      DELETE FROM _mv_stats WHERE mv_name =r.object_identity ;

    END LOOP;
 
END;

$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE EVENT TRIGGER trg_mv_info ON ddl_command_end 
WHEN TAG IN ('CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW','REFRESH MATERIALIZED VIEW')
EXECUTE PROCEDURE fn_trg_mv();

CREATE EVENT TRIGGER trg_mv_info_drop  ON sql_drop
WHEN TAG IN ('DROP MATERIALIZED VIEW') 
EXECUTE PROCEDURE fn_trg_mv_drop();

  

  
CREATE OR REPLACE FUNCTION fn_trg_mv_start()  RETURNS event_trigger AS
$$

BEGIN

  perform set_config('mv_stats.start', clock_timestamp()::text, true);

END;

$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE EVENT TRIGGER trg_mv_info_start  ON ddl_command_start
WHEN TAG IN ('REFRESH MATERIALIZED VIEW')
EXECUTE PROCEDURE fn_trg_mv_start();

CREATE OR REPLACE FUNCTION mv_activity_init () returns setof text AS
$$

  INSERT INTO _mv_stats (mv_name)   
   SELECT schemaname||'.'||matviewname FROM pg_catalog.pg_matviews where schemaname||'.'||matviewname not in (select mv_name from _mv_stats)
   RETURNING mv_name;
 
$$ LANGUAGE sql ;

CREATE OR REPLACE FUNCTION mv_activity_reset_stats (mview variadic text[] DEFAULT array['*']) returns setof text AS
$$
DECLARE 
v text;
 BEGIN 
  FOREACH v IN ARRAY $1 LOOP
   IF v = '*' THEN 
    RETURN query UPDATE _mv_stats SET refresh_mv_last= NULL , refresh_count= 0,refresh_mv_time_last= NULL, refresh_mv_time_total= '00:00:00', refresh_mv_time_min= NULL, refresh_mv_time_max= NULL, reset_last = now() RETURNING mv_name;
   ELSE 
    RETURN query UPDATE _mv_stats SET refresh_mv_last= NULL , refresh_count= 0,refresh_mv_time_last= NULL, refresh_mv_time_total= '00:00:00', refresh_mv_time_min= NULL, refresh_mv_time_max= NULL, reset_last = now() where mv_name=v RETURNING mv_name;
   END IF;
  END LOOP;
  RETURN ; 
 END; 

$$ LANGUAGE plpgsql ;

CREATE OR REPLACE FUNCTION _mv_drop_objects () returns void AS
$$

  DROP FUNCTION mv_activity_reset_stats;
  DROP FUNCTION mv_activity_init;
  DROP EVENT TRIGGER trg_mv_info_start;
  DROP FUNCTION fn_trg_mv_start;
  DROP EVENT TRIGGER  trg_mv_info_drop;
  DROP EVENT TRIGGER  trg_mv_info;
  DROP FUNCTION fn_trg_mv_drop;
  DROP FUNCTION fn_trg_mv;
  DROP VIEW mv_stats;
  DROP TABLE _mv_stats;
  DROP FUNCTION _mv_drop_objects;
 
$$ LANGUAGE sql;

GRANT SELECT ON _mv_stats to public;
GRANT SELECT ON mv_stats to public;

select mv_activity_init ();

