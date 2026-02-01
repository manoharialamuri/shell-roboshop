#!/bin/bash

USERID=$(id -u)

LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"


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

dnf module disable nodejs -y &>> $LOGS_FILE
validate $? "Disabling nodejs default version"

dnf module enable nodejs:20 -y &>> $LOGS_FILE
validate $? "Enabling nodejs version 20"

dnf install nodejs -y &>> $LOGS_FILE
validate $? "Installing nodejs"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "Creating system user"
else
    echo -e "roboshop user already existed...$Y Skipping $N"
fi

mkdir -p /app 
validate $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOGS_FILE
validate $? "Downloading catalogue file"

cd /app
validate $? "moving to app directory"

rm -rf /app/*
validate $? "removing existing code"

unzip /tmp/catalogue.zip &>> $LOGS_FILE
validate $? "unzipping catalogue file"

systemctl daemon-reload
systemctl enable catalogue 
systemctl start catalogue
validate $? "enabling & Starting catalogue"


