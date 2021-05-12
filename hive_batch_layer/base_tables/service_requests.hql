-- Map CSV data in Hive
create external table cloftus_service_requests_csv(
  SR_NUMBER string,
  SR_TYPE string,
  SR_SHORT_CODE string,
  OWNER_DEPARTMENT string,
  STATUS string,
  CREATED_DATE timestamp, 
  LAST_MODIFIED_DATE timestamp,
  CLOSED_DATE timestamp,
  STREET_ADDRESS string,
  CITY string,
  STATE string,
  ZIP_CODE string,
  STREET_NUMBER string,
  STREET_DIRECTION string,
  STREET_NAME string,
  STREET_TYPE string,
  DUPLICATE boolean,
  LEGACY_RECORD boolean,
  LEGACY_SR_NUMBER string,
  PARENT_SR_NUMBER string,
  COMMUNITY_AREA tinyint,
  WARD tinyint,
  ELECTRICAL_DISTRICT string,
  ELECTRICITY_GRID string,
  POLICE_SECTOR string,
  POLICE_DISTRICT string,
  POLICE_BEAT string,
  PRECINCT string,
  SANITATION_DIVISION_DAYS string,
  CREATED_HOUR tinyint,
  CREATED_DAY_OF_WEEK tinyint,
  CREATED_MONTH tinyint,
  X_COORDINATE decimal,
  Y_COORDINATE decimal,
  LATITUDE decimal,
  LONGITUDE decimal,
  LOCATION string)
  row format serde 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
  WITH SERDEPROPERTIES (
   "separatorChar" = "\,",
   "quoteChar"     = "\""
  )
  STORED AS TEXTFILE
    location '/tmp/cloftus/project_data/current_service_requests'
  TBLPROPERTIES("skip.header.line.count"="1");

-- Run a test query to make sure the above worked correctly
select * from cloftus_service_requests_csv limit 5;

-- Create ORC table
create external table cloftus_service_requests(
  SR_NUMBER string,
  SR_TYPE string,
  SR_SHORT_CODE string,
  OWNER_DEPARTMENT string,
  STATUS string,
  CREATED_DATE timestamp, 
  LAST_MODIFIED_DATE timestamp,
  CLOSED_DATE timestamp,
  STREET_ADDRESS string,
  CITY string,
  STATE string,
  ZIP_CODE string,
  STREET_NUMBER string,
  STREET_DIRECTION string,
  STREET_NAME string,
  STREET_TYPE string,
  DUPLICATE boolean,
  LEGACY_RECORD boolean,
  LEGACY_SR_NUMBER string,
  PARENT_SR_NUMBER string,
  COMMUNITY_AREA tinyint,
  WARD tinyint,
  ELECTRICAL_DISTRICT string,
  ELECTRICITY_GRID string,
  POLICE_SECTOR string,
  POLICE_DISTRICT string,
  POLICE_BEAT string,
  PRECINCT string,
  SANITATION_DIVISION_DAYS string,
  CREATED_HOUR tinyint,
  CREATED_DAY_OF_WEEK tinyint,
  CREATED_MONTH tinyint,
  X_COORDINATE decimal,
  Y_COORDINATE decimal,
  LATITUDE decimal,
  LONGITUDE decimal,
  LOCATION string)
  stored as orc;

-- Copy the CSV table to the ORC table
insert overwrite table cloftus_service_requests select * from cloftus_service_requests_csv;

