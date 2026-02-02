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

dnf install python3 gcc python3-devel -y
validate $? "Installing python"
id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "Creating system user"
else
    echo -e "roboshop user already existed...$Y Skipping $N"
fi
mkdir -p /app
validate $? "creating app"
curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip
validate $? "downloading code"
cd /app
validate "moving to app"
unzip /tmp/payment.zip
validate $? "unzipping"
pip3 install -r requirements.txt
validate $? "installing requirements file"
cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
validate $? "creating systemctl service"
systemctl daemon-reload
validate $? "reloading"
systemctl enable payment 
systemctl start payment
validate &? "enable and start"

