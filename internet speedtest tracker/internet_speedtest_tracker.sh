#!/bin/bash

#Internet speed tracker script
#---
#This script automates internet speed tests on your home network for every set interval of time.
#Speed test results are then inserted into a MySQL database running in a MariaDB docker container.
#These results can be visualized using a real-time monitoring tool such as Grafana.

#define interval of speed tests
INTERVAL=3600

#function to insert data into database
insert_results() {
    local download_speed="$1"
    local upload_speed="$2"

    #execute commands within the MariaDB docker container and insert speed test results
    mysql --host $DB_HOST --port 3306 -u $DB_USER -p$DB_PASSWORD $DB_NAME <<EOF
	INSERT INTO speedtest_results (download_speed, upload_speed, test_time)
	VALUES ($download_speed, $upload_speed, '$test_time');
EOF
}

#function to conduct internet speedtests and insert into database
conduct_speed_test() {
    #use speedtest-cli to get download and upload speeds
    speedtest_output=$(speedtest-cli --json)
    download_speed=$(echo "$speedtest_output" | jq -r '.download')
    upload_speed=$(echo "$speedtest_output" | jq -r '.upload')

    #get the current date and time
    test_time=$(date "+%Y-%m-%d %H:%M:%S")

    #insert results into database
    insert_results "$download_speed" "$upload_speed" "$test_time"
}

#infinite loop to conduct speed test for every interval
while true; do
    #call function to conduct speed test
    conduct_speed_test

    #sleep for interval
    sleep $INTERVAL
done
