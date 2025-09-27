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

dnf module disable redis -y
VALIDATE $? "Disable Redis"

dnf module enable redis:7 -y
VALIDATE $? "Enable Redis"

sed -i -e "s/127.0.0.1/0.0.0.0/g" /etc/redis/redis.conf &>>$FILE_LOG
VALIDATE $? "Change ip address 0.0.0.0"

#sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf

sed -i -e "s/protected-mode yes/protected-mode no/g" /etc/redis/redis.conf &>>$FILE_LOG
VALIDATE $? "Change protected-mode yes"

systemctl enable redis 
VALIDATE $? "Enable Redis"

systemctl start redis 
VALIDATE $? "Start Redis"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"