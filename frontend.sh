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

dnf module disable nginx -y &>> $FILE_LOG
VALIDATE $? "Disable NGINX"

dnf module enable nginx:1.24 -y &>> $FILE_LOG
VALIDATE $? "Enable NGINX version 1.24"

dnf install nginx -y &>> $FILE_LOG
VALIDATE $? "Installing NGINX"

systemctl enable nginx  &>> $FILE_LOG
VALIDATE $? "Enable NGINX"

systemctl start nginx &>> $FILE_LOG 
VALIDATE $? "Start NGINX"

rm -rf /usr/share/nginx/html/*  &>> $FILE_LOG
VALIDATE $? " Remove NGINX html file"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $FILE_LOG
VALIDATE $? "Downloading the frontend zip file"

cd /usr/share/nginx/html &>> $FILE_LOG
VALIDATE $? "change directory"

unzip /tmp/frontend.zip &>> $FILE_LOG
VALIDATE $? "Unzip frontend.zip"

cp SCRIPT_DIRECTORY/nginx.conf /etc/nginx/nginx.conf

systemctl restart nginx  &>> $FILE_LOG
VALIDATE $? "Restart    NGINX"