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
cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
validate $? "installing repo"
dnf install rabbitmq-server -y
validate $? "installing server"
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
validate $? "enable and start rabbitmq"
rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
validate $? "Adding user & giving permissions"
