# MPCS 53014 Big Data Application Architecture - Final Project

### Background / Intro

For my project, I was interested in looking at 311 service requests in Chicago and how they had changed over the years. 311 in Chicago has recently been updated, with the hope of making it easier for a wider range of Chicagoans to submit 311 requests. 

I wanted to provide a way to compare current 311 calls across different neighbourhoods in Chicago to historical calls. Since the update, current 311 data has been available as one dataset from the City of Chicago Data Portal. The historic 311 data, however is only available in single datasets for each type of 311 service request. This makes it difficult to easily see the difference in service requests over the years. My project combines the historic 311 datasets for individual categories with the current data, to create one single dataset and webapp where people can see 311 service requests by year for each neighbourhood in Chicago. 

In order to properly compare the two systems, I selected 5 key service request types from the historic datasets (street lights out, rodent baiting requests, graffiti, pot holes, and sanitation code violations) and compared each of these categories with the data from the current system in that category. 

(All source code can be found in the zip file, and I have provided details on how to find the relevant code for each of the sections below)

### Loading data into HDFS

Data is from the City of Chicago Data Portal (https://data.cityofchicago.org/).

I decided to load the data directly into HDFS as schemaless as I did not want to affect the ground truth of the data, and I was confident that the data I was downloading was not corrupt.

#### 1. Chicago current 311 data: 

Dataset from:
https://data.cityofchicago.org/Service-Requests/311-Service-Requests/v6vf-nfxy

Command to load data into HDFS:
```
curl http://data.cityofchicago.org/resource/v6vf-nfxy.csv?\$limit=5000000 | 
hdfs dfs -put - /tmp/cloftus/project_data/service_requests/chicago_311_data.csv
```

#### 2. Chicago neighbourhoods boundaries: 
Community area neighbourhoods dataset (to get neighbourhood names for webapp)

Dataset from:
https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Census-Tracts-2010/5jrd-6zik

Command to load data into HDFS:
```
curl https://data.cityofchicago.org/resource/igwz-8jzy.csv | hdfs dfs -put 
- /tmp/cloftus/project_data/chicago_neighbourhoods/chicago_neighbourhoods.csv
```

#### 3. Historic 311 datasets

All datasets from the following link:

http://dev.cityofchicago.org/open%20data/data%20portal/2018/12/11/legacy-sr-datasets-announcement.html

##### Graffiti:
```
curl https://data.cityofchicago.org/resource/hec5-y4x5.csv?\$limit=5000000
 | hdfs dfs -put -  /tmp/cloftus/project_data/historical_graffiti/historical_graffiti.csv
```

##### Rodent baiting:
```
curl https://data.cityofchicago.org/resource/97t6-zrhs.csv?\$limit=5000000
 | hdfs dfs -put -  /tmp/cloftus/project_data/historical_rodent/historical_rodent.csv
```

##### Pot Holes:
```
curl https://data.cityofchicago.org/resource/7as2-ds3y.csv?\$limit=5000000
 | hdfs dfs -put -  /tmp/cloftus/project_data/historical_potholes/historical_potholes.csv
```

##### Sanitation code:
```
curl https://data.cityofchicago.org/resource/me59-5fac.csv?\$limit=5000000
 | hdfs dfs -put - /tmp/cloftus/project_data/historical_sanitation_code/historical_sanitation_code.csv
```

##### Street lights - all out:
```
curl https://data.cityofchicago.org/resource/zuxi-7xem.csv?\$limit=5000000
 | hdfs dfs -put - /tmp/cloftus/project_data/historical_street_lights_all/historical_street_lights_all.csv
```

##### Street lights - one out:
```
curl https://data.cityofchicago.org/resource/3aav-uy2v.csv?\$limit=5000000
 | hdfs dfs -put - /tmp/cloftus/project_data/historical_street_lights_one/historical_street_lights_one.csv
```
Note: these two street light categories are combined in the current dataset, so I gathered data from both historic datasets and combined together later.


### Batch Layer:

* All queries for batch layer in directory `hive_batch_layer/`

* `hive_batch_layer/base_tables/` contains queries for the base tables (reading in the csv data in HDFS to orc tables in Hive)
    * Note, each historic 311 dataset had a slightly different schema, which is why these had to be processed separately

* `hive_batch_layer/join_historical_requests.hql` contains queries to create a table joining all historic datasets into one

### Serving Layer:

* `hive_batch_layer/service_requests_nbhds.hql` contains code to create the two Hbase tables for the serving layer from Hive:
    - `cloftus_service_requests_nbhds` is the main table that serves the web app
    - `cloftus_neighbourhoods` is a lookup table containing all community area codes and their corresponding neighbourhood name

* Note: before running the above, I first created these tables in Hbase using the following two commands:
    - `create 'cloftus_service_requests_nbhds', 'request'`
    - `create 'cloftus_neighbourhoods', 'nbhd'`

* I also created a counter version of the main table in `hive_batch_layer/counter_service_requests_nbhds.hql`, although I was unable to use this in my app.

### Web app:

Code location:
`project_front_end/` 

The web app consists of two html pages:

-  `service-requests.html` is the main web app page. You should be able to type in a neighbourhood in Chicago (and it will prepopulate with options from the list), and then it will provide a table for the number of 311 requests for that neighbourhood by year and category (categories as discussed above).
    +  **Note**: I decided to design the webapp so that the user inputs the neighbourhood name, as these are meaningful to users in a way that community area codes are not, whereas  community area codes make much more sense than whole neighbourhood names for keys in Hbase. The app then looks up the community area code in the `cloftus_neighbourhoods` HBase table, and uses this result to scan the main Hbase table (`cloftus_service_requests_nbhds`)

-  `submit-service-request.html` is the page to submit fake data for the speed layer. 

#### Deployment:

The web app is deployed on both the single web server and with load balanced deployment at the following locations:

* Single web server:
    http://ec2-3-15-219-66.us-east-2.compute.amazonaws.com:3323/service-requests.html

* Load balanced deployment:
    http://mpcs53014-loadbalancer-217964685.us-east-2.elb.amazonaws.com:3323/service-requests.html

`submit-service-request.html` is also on the deployed app, and should be used to submit fake data to my kafka topic.

### Speed Layer:

My speed layer submits fake data from the `submit-service-request.html` page into my kafka topic (details below). My spark-streaming uberjar is uploaded on the cluster (details below), and when running it takes messages from the kafka topic and populates an Hbase table for the new data (`cloftus_latest_service_requests`). 

Note, I was unfortunately unable to get the code to increment my main Hbase table using this data to work, so that is a limitation of my speed layer. 

#### Kafka topic 
Command used to create kafka topic:
```
./kafka-topics.sh --create --zookeeper z-2.mpcs53014-kafka.fwx2ly.c4.kafka.us-east-2.amazonaws.com:2181,z-3.mpcs53014-kafka.fwx2ly.c4.kafka.us-east-2.amazonaws.com:2181,z-1.mpcs53014-kafka.fwx2ly.c4.kafka.us-east-2.amazonaws.com:2181 --replication-factor 2 --partitions 1 --topic cloftus-service-reports
```

Command used to check kafka topic was receiving messages:
```
kafka-console-consumer.sh --bootstrap-server b-1.mpcs53014-kafka.fwx2ly.c4.kafka.us-east-2.amazonaws.com:9092,b-2.mpcs53014-kafka.fwx2ly.c4.kafka.us-east-2.amazonaws.com:9092 --topic cloftus-service-reports --from-beginning
```

#### Spark streaming

Code location:
`project_speed_layer/`

Hbase command to create table: ```create 'cloftus_latest_service_requests', 'request'```

Spark-submit command:
```
spark-submit --master local[2] --driver-java-options "-Dlog4j.configuration=file:///home/hadoop/ss.log4j.properties" --class StreamServiceRequests cloftus/src/target/uber-project_speed_layer-1.0-SNAPSHOT.jar b-1.mpcs53014-kafka.fwx2ly.c4.kafka.us-east-2.amazonaws.com:9092,b-2.mpcs53014-kafka.fwx2ly.c4.kafka.us-east-2.amazonaws.com:9092
```

Once the spark-submit is running, please go to `submit-service-request.html` on either my load balanced or single server app, and submit some fake service requests. 

You should be able to see these requests in the Hbase table by running `scan 'cloftus_latest_service_requests'` in Hbase.

