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


dnf install python3 gcc python3-devel -y &>>$FILE_LOG
VALIDATE $? "Installing python3"

id roboshop &>> $FILE_LOG
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$FILE_LOG
    VALIDATE $? "create system user"
else
    echo -e " $Y System user is already created $N"
fi

mkdir -p /app  &>>$FILE_LOG
VALIDATE $? "create directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$FILE_LOG
cd /app  &>>$FILE_LOG

rm -rf /app/* 
VALIDATE $? "removing existing code"

unzip /tmp/payment.zip  &>>$FILE_LOG
VALIDATE $? "unzip"

cd /app 
cp $SCRIPT_DIRECTORY/payment.service /etc/systemd/system/payment.service 

pip3 install -r requirements.txt &>>$FILE_LOG
VALIDATE $? "mvn clean package" 


systemctl daemon-reload &>>$FILE_LOG
VALIDATE $? "Daemon reload"

systemctl enable payment &>>$FILE_LOG
VALIDATE $? "enable payment" 

systemctl start payment &>>$FILE_LOG
VALIDATE $? "start payment"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
