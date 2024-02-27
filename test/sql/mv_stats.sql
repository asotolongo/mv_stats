\set ECHO none

CREATE EXTENSION mv_stats;
--create MV
create materialized view public.mv_act as select * from pg_stat_activity ;
create materialized view public.mv_bgw as select * from pg_stat_bgwriter ;
create materialized view public.mv_dat as select * from pg_stat_database ;
--refresh MVs
refresh materialized view public.mv_act; 
refresh materialized view public.mv_bgw;
refresh materialized view public.mv_dat;
--query mv_stats
select mv_name, refresh_count from public.mv_stats;
--refresh a MV
refresh materialized view public.mv_act; 
--reset public.mv_act  MVs stats
select * from public.mv_activity_reset_stats('public.mv_act');
--query mv_stats
select mv_name, refresh_count from public.mv_stats;
--reset all MVs
select * from public.mv_activity_reset_stats('*');
--query mv_stats
select mv_name, refresh_count from public.mv_stats;