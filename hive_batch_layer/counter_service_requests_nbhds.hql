create external table cloftus_counter_service_requests_nbhds (
  commarea_year string, 
  street_lights bigint,
  rodents bigint, graffiti bigint,
  potholes bigint, sanitation_codes bigint)
STORED BY 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
WITH SERDEPROPERTIES ('hbase.columns.mapping' = ':key,request:street_lights#b,request:rodents#b,request:graffiti#b,request:potholes#b,request:sanitation_codes#b')
TBLPROPERTIES ('hbase.table.name' = 'cloftus_counter_service_requests_nbhds');

insert overwrite table cloftus_counter_service_requests_nbhds
  select concat(concat(lpad(a.commarea, 2, "0"), '_'), year) as commarea_year, sum(a.street_lights) as street_light_requests, sum(a.rodents) as rodent_requests, sum(a.graffiti) as graffiti_requests, sum(a.potholes) as pothole_requests, sum(a.sanitation_code) as sanitation_code_requests
  from (
    (select cast(community_area as string) as commarea, cast(date_format(CREATED_DATE,'yyyy') as int) as year,
    sum(if(sr_type == 'Street Light Out Complaint', 1, 0)) as street_lights,
    sum(if(sr_type == 'Rodent Baiting/Rat Complaint', 1, 0)) as rodents,
    sum(if(sr_type == 'Graffiti Removal Request', 1, 0)) as graffiti,
    sum(if(sr_type == 'Pothole in Street Complaint', 1, 0)) as potholes,
    sum(if(sr_type == 'Sanitation Code Violation', 1, 0)) as sanitation_code
    from cloftus_service_requests
    where legacy_record = false
    group by COMMUNITY_AREA, date_format(CREATED_DATE,'yyyy'))
    union all
    (select * from cloftus_agg_historical)) a
  where a.commarea is not null
  and a.year is not null
  group by a.commarea, a.year;

