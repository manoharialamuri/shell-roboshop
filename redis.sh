#!/bin/bash

USERID=$(id -u)

LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"
SCRIPT_DIR=$PWD
#MONGO_HOST=mongodb.daws88s.store


if [ $USERID -ne 0 ]; then
    echo "Please use root access" | tee -a $LOGS_FILE
    exit 12
fi

mkdir -p $LOGS_FOLDER

validate(){
    if [ $1 -ne 0 ]; then
        echo "$2... Failed" | tee -a $LOGS_FILE
        exit 30
    else
        echo "$2.. Success" | tee -a $LOGS_FILE
    fi
}

dnf module enable redis:7 -y &>> $LOGS_FILE
validate $? "Enabling redis 7"
dnf install redis -y | tee -a $LOGS_FILE
validate $? "Installing redis"
systemctl enable redis &>> $LOGS_FILE
systemctl start redis
validate $? "Enabling and starting redis" 
sed -i 's/protected-mode yes/protected-mode no/g' /etc/redis/redis.conf &>> $LOGS_FILE
validate $? "Disabling protected mode"
sed -i 's/127.0.0.1 /0.0.0.0/g' /etc/redis/redis.conf &>> $LOGS_FILE
validate $? "Updating redis bind address"
systemctl restart redis 
validate $? "restarting redis"
