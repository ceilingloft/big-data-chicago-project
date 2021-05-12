-- Map CSV data in Hive
create external table cloftus_historical_rodent_csv(
  CREATION_DATE timestamp,
  STATUS string,
  COMPLETION_DATE timestamp,
  SERVICE_REQUEST_NUMBER string,
  SERVICE_REQUEST_TYPE string,
  RODENT_DETAILS1 int,
  RODENT_DETAILS_2 int,
  RODENT_DETAILS_3 int,
  CURRENT_ACTIVITY string,
  MOST_RECENT_ACTION string,
  ADDRESS string,
  ZIP int,
  X_COORDINATE decimal,
  Y_COORDINATE decimal,
  WARD tinyint,
  POLICE_DISTRICT string,
  COMMUNITY_AREA tinyint,
  LATITUDE decimal,
  LONGITUDE decimal,
  LOCATION string)
  row format serde 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
  WITH SERDEPROPERTIES (
   "separatorChar" = "\,",
   "quoteChar"     = "\""
  )
  STORED AS TEXTFILE
    location '/tmp/cloftus/project_data/historical_rodent'
  TBLPROPERTIES("skip.header.line.count"="1");

-- Run a test query to make sure the above worked correctly
select * from cloftus_historical_rodent_csv limit 5;

-- Create ORC table
create external table cloftus_historical_rodent(
  CREATION_DATE timestamp,
  STATUS string,
  COMPLETION_DATE timestamp,
  SERVICE_REQUEST_NUMBER string,
  SERVICE_REQUEST_TYPE string,
  RODENT_DETAILS1 int,
  RODENT_DETAILS_2 int,
  RODENT_DETAILS_3 int,
  CURRENT_ACTIVITY string,
  MOST_RECENT_ACTION string,
  ADDRESS string,
  ZIP int,
  X_COORDINATE decimal,
  Y_COORDINATE decimal,
  WARD tinyint,
  POLICE_DISTRICT string,
  COMMUNITY_AREA tinyint,
  LATITUDE decimal,
  LONGITUDE decimal,
  LOCATION string)
  stored as orc;

-- Copy the CSV table to the ORC table
insert overwrite table cloftus_historical_rodent select * from cloftus_historical_rodent_csv;



 