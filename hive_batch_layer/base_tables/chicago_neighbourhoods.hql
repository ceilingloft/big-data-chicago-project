-- Map CSV data in Hive
create external table cloftus_chicago_nbhds_csv(
  Geom string,
  Perimeter string,
  Area tinyint,
  Commarea tinyint,
  Commarea_id tinyint,
  Area_number tinyint,
  Community string,
  Area_num1 tinyint,
  shape_area decimal,
  shape_len decimal)
  row format serde 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
  WITH SERDEPROPERTIES (
    "separatorChar" = "\,",
    "quoteChar" = "\""
  )
  STORED AS TEXTFILE
    location '/tmp/cloftus/project_data/chicago_neighbourhoods'
  TBLPROPERTIES("skip.header.line.count"="1");

-- Run a test query to make sure the above worked correctly
select * from cloftus_chicago_nbhds_csv limit 5;

-- Create ORC table
create external table cloftus_chicago_nbhds(
  Geom string,
  Perimeter string,
  Area tinyint,
  Commarea tinyint,
  Commarea_id tinyint,
  Area_number tinyint,
  Community string,
  Area_num1 tinyint,
  shape_area decimal,
  shape_len decimal)
  stored as orc;

-- Copy the CSV table to the ORC table
insert overwrite table cloftus_chicago_nbhds select * from cloftus_chicago_nbhds_csv;

