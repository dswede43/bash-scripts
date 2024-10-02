#!/bin/bash

#DB Container Backup Script
# ---
#This script automates backups of individual databases running in docker containers.
#It currently supports mariadb and vaultwarden containers.
#This script was modified from ChristianLempa at https://github.com/ChristianLempa/scripts/blob/main/db-container-backup/db-container-backup.sh

#set the number of backups to keep
NUM_BACKUPS=7

#define the backups directory
BACKUPDIR="/path/to/backups/directory"

#create a backups directory if does not exist
if [ ! -d $BACKUPDIR ]; then
    mkdir -p $BACKUPDIR
fi

#mariaDB backup
#define the database container name
CONTAINER=mariadb
echo $CONTAINER

#define the database root password
MYSQL_PWD=$(docker exec $CONTAINER env | grep MYSQL_ROOT_PASSWORD |cut -d"=" -f2)

#find the names of all running databases
DATABASES=($(docker exec -i "$CONTAINER" mysql -u root -p"$MYSQL_PWD" -e 'SHOW DATABASES';))
DATABASES=("${DATABASES[@]:1}") #remove the first element from the array
DATABASES=("${DATABASES[@]/information_schema}") #remove information_schema database
DATABASES=("${DATABASES[@]/performance_schema}") #remove performance_schema database
echo ${DATABASES[@]}

#create a directory for each database
for i in ${DATABASES[@]}; do
    if [ ! -d $i ]; then
        mkdir -p $i
    fi
done

#for each running database
for i in ${DATABASES[@]}; do
    DATABASE=$i #define the database

    #create database dumps and backup files
    docker exec -e DATABASE=$DATABASE -e MYSQL_PWD=$MYSQL_PWD \
        $CONTAINER /usr/bin/mysqldump -u root $DATABASE \
        | gzip > $BACKUPDIR/$DATABASE/$CONTAINER-$DATABASE-$(date +"%Y%m%d%H%M").sql.gz

    #remove old backups
    OLD_BACKUPS=$(ls -1 $BACKUPDIR/$i/$CONTAINER*.gz |wc -l)
    if [ $OLD_BACKUPS -gt $NUM_BACKUPS ]; then
        find $BACKUPDIR/$DATABASE/ -name "$CONTAINER*.gz" -daystart -mtime +$DAYS -delete
    fi
done

#vaultwarden backup
VAULTWARDEN_CONTAINERS=$(docker ps --format '{{.Names}}:{{.Image}}' | grep 'vaultwarden' | cut -d":" -f1)

#for each vaultwarden container
for i in $VAULTWARDEN_CONTAINERS; do
	#create database dumps and backup files
    docker exec  $i /usr/bin/sqlite3 data/db.sqlite3 .dump \
        | gzip > $BACKUPDIR/vaultwarden/$i-$(date +"%Y%m%d%H%M").sql.gz

	#remove old backups
    OLD_VAULTWARDEN_BACKUPS=$(ls -1 $BACKUPDIR/vaultwarden/$i*.gz |wc -l)
    if [ $OLD_VAULTWARDEN_BACKUPS -gt $NUM_BACKUPS ]; then
        find $BACKUPDIR/vaultwarden/ -name "$i*.gz" -daystart -mtime +$DAYS -delete
    fi
done
