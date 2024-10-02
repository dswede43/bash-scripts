#!/bin/bash

#Backup desktop PC
#---
#Script to automate the backups of a directory from a Linux desktop PC
#or a Win10 PC running WSL.


#define global variables
SOURCE_DIR="/mnt/g/Data" #path to source of backup
DEST_DIR="/mnt/sgdrive/backups/desktop" #path to destination of backup
DEST_USER="dan" #destination server username
DEST_IP="192.168.1.194" #destination server IP

#get the current date and time for the backup folder
DATE=$(date +%Y-%m-%d_%H-%M-%S)

#create a temporary compressed tar file with only the changes since the last backup
tar_file="/tmp/backup_$DATE.tar.gz"

#create a compressed archive of the directory
echo "Creating a compressed archive of $SOURCE_DIR..."
tar -czf $tar_file "$SOURCE_DIR" .

#perform an incremental backup using rsync (over SSH)
echo "Starting the backup process..."
rsync -avz --ignore-existing $tar_file $DEST_USER@$DEST_IP:$DEST_DIR

#remove the temporary tar file after successful transfer
if [ $? -eq 0 ]; then
    echo "Backup successful. Removing temporary files..."
    rm -fv $tar_file
else	
    echo "Backup failed. Keeping temporary files for inspection."
fi

echo "Backup process completed!"
