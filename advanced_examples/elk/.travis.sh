#!/bin/bash

./create-certs
docker-compose up -d
# Wait for elasticsearch and logstash to finish startup
until curl -s 'localhost:9200/_cluster/health?wait_for_status=yellow'; do sleep 5; echo "waiting for elasticsearch to finish startup"; done
until curl -s 'localhost:9600/_node'; do sleep 5; echo "waiting for logstash to finish startup"; done
# Create counter
curl --cacert ssl/dockerwatch-ca.pem -H 'Content-Type: application/json' -X POST -d '' https://localhost:8443/cnt
# Increment counter
curl --cacert ssl/dockerwatch-ca.pem -H 'Content-Type: application/json' -X POST -d '{}' https://localhost:8443/cnt
# Read all counters
curl --cacert ssl/dockerwatch-ca.pem -H 'Accept: application/json' https://localhost:8443/
# Read the counter `cnt` as json
curl --cacert ssl/dockerwatch-ca.pem -H 'Accept: application/json' https://localhost:8443/cnt
# Increment the counter `cnt` by 20
curl --cacert ssl/dockerwatch-ca.pem -H 'Content-Type: application/json' -X POST -d '{\"value\":20}' https://localhost:8443/cnt
# Read the counter `cnt` as text
curl --cacert ssl/dockerwatch-ca.pem -H 'Accept: text/plain' https://localhost:8443/cnt
# Check that there are 6 lines in the logstash log (one for each curl command above)
sleep 10
test "$(docker exec dockererlangexample_logstash_1 cat /usr/share/logstash/logs/output.log | wc -l)" = "6"
# Get the index name, and check that there are also 6 log events to be read from elasticsearch
INDEX=$(curl -s 'localhost:9200/_cat/indices/logstash*?h=i')
echo $INDEX
S=$(curl -s "localhost:9200/$INDEX/_search?_source=false")
echo $S
T=$(curl -s "localhost:9200/$INDEX/_search?_source=false" | jq -r ".hits.total")
echo $T
test "$T" = "6"
