#?/bin/bash
USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
FILE_LOG_DIRECTORY="/var/log/shell-roboshop/"
SCRIPT_NAME=$(echo $0 | cut -d '.' -f1)
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

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$FILE_LOG
VALIDATE $? "Adding mongo repo"
dnf install mongodb-org -y &>>$FILE_LOG
VALIDATE $? "mongodb" 
systemctl enable mongod &>>$FILE_LOG
VALIDATE $? "Systemctl enable"  
systemctl start mongod &>>$FILE_LOG
VALIDATE $? "Systemctl start" 
sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf &>>$FILE_LOG
VALIDATE $? "allowing remote connections mongodb" 
systemctl restart mongod &>>$FILE_LOG
VALIDATE $? "Systemctl restart" 