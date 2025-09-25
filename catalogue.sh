#?/bin/bash
USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
FILE_LOG_DIRECTORY="/var/log/shell-roboshop/"
SCRIPT_NAME=$(echo $0 | cut -d '.' -f1)
SCRIPT_DIRECTORY=$PWD
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

id roboshop &>> $FILE_LOG
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$FILE_LOG
    VALIDATE $? "create system user"
else
    echo -e " $Y System user is already created $N"
fi

mkdir -p /app  &>>$FILE_LOG
VALIDATE $? "create directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$FILE_LOG
cd /app  &>>$FILE_LOG

rm -rf /app/*
VALIDATE $? "removing existing code"

unzip /tmp/catalogue.zip  &>>$FILE_LOG
VALIDATE $? "unzip"

cd /app 
cp $SCRIPT_DIRECTORY/catalogue.service /etc/systemd/system/catalogue.service

npm install &>>$FILE_LOG
VALIDATE $? "npm install" 

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

INDEX=$(mongosh mongodb.msgd.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_SERVER </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Load catalogue products"
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue  &>>$FILE_LOG  
VALIDATE $? "systemctl restart"