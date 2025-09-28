#?/bin/bash
START_TIME=$(date +%s)
USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
FILE_LOG_DIRECTORY="/var/log/shell-roboshop/"
SCRIPT_NAME=$(echo $0 | cut -d '.' -f1)
SCRIPT_DIRECTORY=$PWD
FILE_LOG=$FILE_LOG_DIRECTORY/$SCRIPT_NAME.log
MYSQL_HOST="mysql.msgd.fun"
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


dnf install maven -y &>>$FILE_LOG
VALIDATE $? "Installing maven"

id roboshop &>> $FILE_LOG
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$FILE_LOG
    VALIDATE $? "create system user"
else
    echo -e " $Y System user is already created $N"
fi

mkdir -p /app  &>>$FILE_LOG
VALIDATE $? "create directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$FILE_LOG
cd /app  &>>$FILE_LOG

rm -rf /app/* 
VALIDATE $? "removing existing code"

unzip /tmp/shipping.zip  &>>$FILE_LOG
VALIDATE $? "unzip"

cd /app 
cp $SCRIPT_DIRECTORY/shipping.service /etc/systemd/system/shipping.service 


mvn clean package &>>$FILE_LOG
VALIDATE $? "mvn clean package" 

mv target/shipping-1.0.jar shipping.jar  
VALIDATE $? "move the shipping.jar file"

systemctl daemon-reload &>>$FILE_LOG
VALIDATE $? "Daemon reload"

systemctl enable shipping &>>$FILE_LOG
VALIDATE $? "enable shipping" 

systemctl start shipping &>>$FILE_LOG
VALIDATE $? "start shipping"

dnf install mysql -y  &>>$FILE_LOG


mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$FILE_LOG

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
