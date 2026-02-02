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
MONGO_HOST=mongodb.daws88s.store


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

dnf module enable nodejs:20 -y
validate $? "enabling nodejs-20"
dnf install nodejs -y &>> $LOGS_FILE
validate $? "installing nodejs"
id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    echo $? "creating system user"
else
    echo -e "User already created...$Y Skipping $N"
fi
mkdir -p /app
validate $? "Creating directory" 
curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>> $LOGS_FILE
validate $? "downloading code"
cd /app 
validate $? "moving to app directory"
rm -rf /app/*
validate $? "removing existing code"
unzip /tmp/cart.zip &>> $LOGS_FILE
validate $? "unzipping the code"
npm install &>> $LOGS_FILE
validate $? "installing dependencies"
cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
validate $? "copying systemctl service"
systemctl daemon-reload
validate $? "reloaded"
systemctl enable cart &>> $LOGS_FILE
systemctl start cart
validate $? "Enable and start cart"
