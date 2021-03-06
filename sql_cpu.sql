-- %D%  sql_cpu.sql  - shows top sql queries / execution plan ordered by buffer gets
-- %D%  example:  @sql_cpu.sql
-- %D%  date: 08.10.2015
-- %D%  query against V$SQL and DBA_USERS
-- %D%  varsion 1.00

set lines 150
prompt 
prompt
prompt ************************************************************************
prompt *** Top 20 CPU usage (kumulativ) Statements, except SYS,SYSTEM 
prompt ************************************************************************

SET pages 3000
SET lines  1200
SET trimspool ON
SET trimout   ON


column cpu   heading 'CPU Time' format 99999999D99
column proc heading 'Total %' format 9999999D99
column dr   heading 'Disc Reads' format 999999999
column et   heading 'Elapse Time' format 99999999D9
column ex   heading 'Executions' format 9999999999
column etpe heading 'Elapsed/Exec' format 99999D99
column cis  heading 'CPU' format 999999D99
column cpe  heading 'CPU/Exec' format 99999D99
column pr   heading 'DRead/Exec' format 9999999D9
column si   heading 'Sql Id' format 9999999999
column un   heading 'User name' format 999999
column oc   heading 'Optimazer Cost' format 9999999999
column cn   heading 'Child number' format 9999999999


select * from (
select a.cpu_time/1000000 as "cpu", 
cpu_time*100/(select sum(cpu_time) from v$sql a left join
dba_users b on a.parsing_schema_id = b.user_id where executions>0 and a.parsing_schema_id not in (0,5)) as proc,
a.elapsed_time/1000000 as et,
a.executions as ex,
a.cpu_time/executions/1000000 as "cpe", 
elapsed_time/executions/1000000  as "etpe",
a.disk_reads/executions as "pr", 
a.sql_id as si, 
b.username as un, 
a.optimizer_cost as oc, 
a.child_number as cn
from
v$sql a left join
dba_users b on a.parsing_schema_id = b.user_id where executions>0 and a.parsing_schema_id not in (0,5)
order by a.cpu_time desc) 
where ROWNUM < 21;


prompt *****************************************************************************
prompt **********        FIRST Execution Plan - user not SYS, SYSTEM, DBSNMP, NAGIOS
prompt *****************************************************************************


select 
plan_table_output from v$sql s, table(dbms_xplan.display_cursor(s.sql_id, s.child_number, 'TYPICAL')) t
where  
s.sql_id =(select distinct sql_id from v$sql where SQL_ID = (select sql_id from (select sql_fulltext, sql_id from v$sql
where parsing_schema_id not in (0,5) 
and optimizer_cost IS NOT NULL 
order by cpu_time desc) 
where rownum < 2));


prompt ******************************************************************************
prompt **********        SECOND Execution Plan - user not SYS, SYSTEM, DBSNMP, NAGIOS
prompt ******************************************************************************


select plan_table_output from v$sql s, table(dbms_xplan.display_cursor(s.sql_id, s.child_number, 'TYPICAL')) t
where  
s.sql_id =(select distinct sql_id from v$sql where SQL_ID = (select sql_id from (select sql_id, row_number() over (order by cpu_time desc) r from v$sql
where parsing_schema_id not in (0,5) and optimizer_cost IS NOT NULL and optimizer_cost <> 0
) 
where r = 2));


prompt ******************************************************************************
prompt **********        THIRD Execution Plan - user not SYS, SYSTEM, DBSNMP, NAGIOS
prompt ******************************************************************************


select plan_table_output from v$sql s, table(dbms_xplan.display_cursor(s.sql_id, s.child_number, 'TYPICAL')) t
where  
s.sql_id =(select distinct sql_id from v$sql where SQL_ID = (select sql_id from (select sql_id, row_number() over (order by cpu_time desc) r from v$sql
where parsing_schema_id not in (0,5) and optimizer_cost IS NOT NULL and optimizer_cost <> 0
) 
where r = 3));

