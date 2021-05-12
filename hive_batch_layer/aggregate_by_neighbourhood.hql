create table cloftus_agg_nbhds (
  Community_name string,
  Commarea bigint,
  Total_income bigint,
  Total_pop bigint,
  Income_pc decimal)
  stored as orc;

insert overwrite table cloftus_agg_nbhds
  select n.Community, a.Commarea, a.Total_income, a.Total_pop, (a.total_income/a.total_pop) as Income_pc
  from (
    select Commarea, 
      sum(if(Agg_income != -666666666, Agg_income, 0)) as Total_income,
      sum(if(Total_pop != -666666666, Total_pop, 0)) as Total_pop
    from cloftus_census_and_boundaries group by Commarea) a
  join cloftus_chicago_nbhds n
  on a.Commarea = n.Area_number
  order by income_pc;
