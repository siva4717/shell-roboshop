#?/bin/bash
USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
FILE_LOG_DIRECTORY="/var/log/shell-roboshop/"
SCRIPT_NAME=$(echo $0 | cut -d '.' -f1)
SCRIPT_DIRECTORY=$pwd
FILE_LOG=$FILE_LOG_DIRECTORY/$SCRIPT_NAME.log
MONGODB_SERVER="mongodb.msgd.fun"
mkdir -p $FILE_LOG_DIRECTORY 
echo -e "$G The script Started at ::: $(date)$N"

if [ $USER_ID -ne 0 ]; then 
    echo -e " $R You can use root user $N" 
    exit 1
    
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e " $2 ... $R failure $N "
    else
        echo -e " $2 ... $G success $N "
    fi
}

dnf module disable nodejs -y &>>$FILE_LOG
VALIDATE $? "Disable nodejs" &>>$FILE_LOG
dnf module enable nodejs:20 -y &>>$FILE_LOG
VALIDATE $? "Enable nodejs:20"
dnf install nodejs -y &>>$FILE_LOG
VALIDATE $? "Installing nodejs"
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$FILE_LOG
VALIDATE $? "create system user"
mkdir -p /app  &>>$FILE_LOG
VALIDATE $? "create directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$FILE_LOG
cd /app  &>>$FILE_LOG
unzip /tmp/catalogue.zip v
VALIDATE $? "unzip"
cd /app &>>$FILE_LOG
cp $SCRIPT_DIRECTORY/catalogue.service /etc/systemd/system/catalogue.service &>>$FILE_LOG
npm install &>>$FILE_LOG
VALIDATE $? "npm install" &>>$FILE_LOG
systemctl daemon-reload &>>$FILE_LOG
VALIDATE $? "Daemon reload"
systemctl enable catalogue &>>$FILE_LOG
VALIDATE $? "enable catalogue" 
systemctl start catalogue &>>$FILE_LOG
VALIDATE $? "start catalogue"
cp $SCRIPT_DIRECTORY/mongo.repo /etc/yum.repos.d/mongo.repo &>>$FILE_LOG
VALIDATE $? "adding mongo repo"
dnf install mongodb-mongosh -y &>>$FILE_LOG
VALIDATE $? "Installing mongosh"
mongosh --host $MONGODB_SERVER </app/db/master-data.js &>>$FILE_LOG
VALIDATE $? "systemctl restart"
mongosh --host $MONGODB_SERVER &>>$FILE_LOG
VALIDATE $? "systemctl restart"
systemctl restart catalogue &>>$FILE_LOG
VALIDATE $? "systemctl restart"