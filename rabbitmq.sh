#?/bin/bash

START_TIME=$(date +%s)
USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
FILE_LOG_DIRECTORY="/var/log/shell-roboshop/"
SCRIPT_NAME=$(echo $0 | cut -d '.' -f1)
FILE_LOG=$FILE_LOG_DIRECTORY/$SCRIPT_NAME.log
SCRIPT_DIRECTORY=$PWD
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

cp $SCRIPT_DIRECTORY/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo  &>>$FILE_LOG
VALIDATE $? "rabbitmq-repo"

dnf install rabbitmq-server -y &>>$FILE_LOG
VALIDATE $? "install rabbitmq-server"

systemctl enable rabbitmq-server &>>$FILE_LOG
VALIDATE $? "Enable rabbitmq-server"

systemctl start rabbitmq-server &>>$FILE_LOG
VALIDATE $? "start rabbitmq-server"


id roboshop &>> $FILE_LOG
if [ $? -ne 0 ]; then
    rabbitmqctl add_user roboshop roboshop123
    VALIDATE $? "rabbitmqctl add_user roboshop roboshop123"
    rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
    VALIDATE $? "rabbitmqctl set_permissions"
else
    echo -e " $Y roboshop user is already created $N"
fi




END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"