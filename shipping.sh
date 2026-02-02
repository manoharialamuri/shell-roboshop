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
MYSQL_HOST=mysql.daws88s.store


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

dnf install maven -y
validate $? "Installing maven"
id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    echo $? "Creating system user"
else
    echo -e "User already created.. $Y Skipping $N"
fi
mkdir -p /app &>> $LOGS_FILE
validate &? "Creating app directory"
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOGS_FILE
validate $? "downloading code"
cd /app &>> $LOGS_FILE
validate $? "moving to app"
rm -rf /app/*
validate $? "Removing existing code"
unzip /tmp/shipping.zip &>> $LOGS_FILE
validate $? "unzipping"
mvn clean package &>> $LOGS_FILE
validate $? "installing dependenices"
mv target/shipping-1.0.jar shipping.jar
validate $? "renaming"
cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
validate $? "copying"
systemctl daemon-reload
validate $? "reloading"
systemctl enable shipping 
systemctl start shipping
validate $? "Enable and start"
dnf install mysql -y 
validate $? "installing mysql"
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
if [ $? -lt 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
    validate $? "loading schemas"
else
    echo -e "Schemas already loaded... $Y Skipping $N"
fi
systemctl restart shipping
validate $? "restarting"

