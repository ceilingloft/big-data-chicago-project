create table cloftus_agg_historical (
  commarea string,
  year int,
  street_lights bigint,
  rodents bigint,
  graffiti bigint,
  potholes bigint,
  sanitation_code bigint)
  stored as orc;

insert overwrite table cloftus_agg_historical
  select sla.community_area, cast(sla.created_year as int), 
         (sla.street_lights_all + slo.stree_lights_one) as street_lights,
         r.rodents, g.graffiti, p.potholes, sc.sanitation_code
  from (
    select community_area, date_format(CREATION_DATE,'yyyy') as created_year, count(*) as street_lights_all 
    from cloftus_historical_street_lights_all
    where community_area is not null
    group by community_area, date_format(CREATION_DATE,'yyyy')) sla
  join (
    select community_area, date_format(CREATION_DATE,'yyyy') as created_year, count(*) as rodents 
    from cloftus_historical_rodent
    where community_area is not null
    group by community_area, date_format(CREATION_DATE,'yyyy')) r
  on sla.community_area = r.community_area and sla.created_year = r.created_year
  join (
    select community_area, date_format(CREATION_DATE,'yyyy') as created_year, count(*) as stree_lights_one 
    from cloftus_historical_street_lights_one
    where community_area is not null
    group by community_area, date_format(CREATION_DATE,'yyyy')) slo
  on sla.community_area = slo.community_area and sla.created_year = slo.created_year
  join (
    select community_area, date_format(CREATION_DATE,'yyyy') as created_year, count(*) as graffiti 
    from cloftus_historical_graffiti
    where community_area is not null
    group by community_area, date_format(CREATION_DATE,'yyyy')) g
  on sla.community_area = g.community_area and sla.created_year = g.created_year
  join (
    select community_area, date_format(CREATION_DATE,'yyyy') as created_year, count(*) as potholes 
    from cloftus_historical_potholes
    where community_area is not null
    group by community_area, date_format(CREATION_DATE,'yyyy')) p
  on sla.community_area = p.community_area and sla.created_year = p.created_year
  join (
    select community_area, date_format(CREATION_DATE,'yyyy') as created_year, count(*) as sanitation_code 
    from cloftus_historical_sanitation_code
    where community_area is not null
    group by community_area, date_format(CREATION_DATE,'yyyy')) sc
  on sla.community_area = sc.community_area and sla.created_year = sc.created_year;
