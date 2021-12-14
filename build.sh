#!/bin/bash

#Get options
removetoken_flag=false
gitnewsource_flag=false
clonesource_flag=false
initnewproj_flag=false
databasesync_flag=false
syncresources_flag=false
packageinstall_flag=false
nocachebuild_flag=false
xbuildproduction_flag=false
while getopts ":hrgcidspnx" option; do
  case $option in
    h) echo -e "usage: $0 
    [-h] Help 
    [-r] Remove saved github personal access token 
    [-g] Git new source update 
    [-c] Clone Source instead Pull 
    [-i] Init New Project in folder src 
    [-d] Database Sync from Production 
    [-p] Packages Install (npm)  
    [-n] No cache layers when build
    [-x] xBuild app image and stacks for PRODUCTION (default is build for Dev)"; exit ;;
    r) removetoken_flag=true ;;
    g) gitnewsource_flag=true ;;
    c) clonesource_flag=true ;;
    i) initnewproj_flag=true ;;
    d) databasesync_flag=true ;;
    s) syncresources_flag=true ;;
    p) packageinstall_flag=true ;;
    n) nocachebuild_flag=true ;;
    x) xbuildproduction_flag=true ;;
    ?) echo "error: option -$OPTARG is not implemented"; exit ;;
  esac
done

#Get app .env
COMPOSE_PROJECT_NAME=$(grep COMPOSE_PROJECT_NAME .env | grep -v -e '^\s*#' | cut -d '=' -f 2- | tr -d '"\r\n')
GIT_REPO=$(grep GIT_REPO .env | grep -v -e '^\s*#' | cut -d '=' -f 2- | tr -d '"\r\n')
GIT_BRANCH=$(grep GIT_BRANCH .env | grep -v -e '^\s*#' | cut -d '=' -f 2- | tr -d '"\r\n')
DB_DATABASE=$(grep DB_DATABASE .env | grep -v -e '^\s*#' | cut -d '=' -f 2- | tr -d '"\r\n')
DB_USERNAME=$(grep DB_USERNAME .env | grep -v -e '^\s*#' | cut -d '=' -f 2- | tr -d '"\r\n')
DB_PASSWORD=$(grep DB_PASSWORD .env | grep -v -e '^\s*#' | cut -d '=' -f 2- | tr -d '"\r\n')
SSH_REMOTE_SERVER=$(grep SSH_REMOTE_SERVER .env | grep -v -e '^\s*#' | cut -d '=' -f 2- | tr -d '"\r\n')
SSH_REMOTE_SERVER_USER=$(grep SSH_REMOTE_SERVER_USER .env | grep -v -e '^\s*#' | cut -d '=' -f 2- | tr -d '"\r\n')
SSH_REMOTE_SERVER_PASSWORD=$(grep SSH_REMOTE_SERVER_PASSWORD .env | grep -v -e '^\s*#' | cut -d '=' -f 2- | tr -d '"\r\n')

#Init New Project
if [ "$initnewproj_flag" = true ]; then
    docker run -it --rm -v `pwd`:/usr/src/app -w /usr/src/app -u $(id -u ${USER}):$(id -g ${USER}) node:16-alpine sh -c "npm init adonis-ts-app@latest src"
fi

#Get github personal access token
if [ ! -s .githubpatcache ]; then # Checks if file NOT exist and has size greater than 0
    echo -e "Notes: Please paste your Github Personal Access Token below ! \nGet it here https://github.com/settings/tokens \n\nEnter your Personal Access Token:"
    read githubpat
    echo "$githubpat" > .githubpatcache
else #file exist, read it
    githubpat=$(<.githubpatcache)
fi

#Clone or Pull source
if [ "$gitnewsource_flag" = true ]; then
    if [ "$clonesource_flag" = true ]; then #clone
        sudo rm -rf ./src && git clone https://$githubpat@${GIT_REPO} -b ${GIT_BRANCH} src
    else #pull
        cd ./src && git pull https://$githubpat@${GIT_REPO} ${GIT_BRANCH} && cd ../
    fi

    #Chmod 777 for Source Folder
    chmod 777 ./src

fi

#Remember or Forget Github personal access token cache
if [ "$removetoken_flag" = true ]; then
    rm .githubpatcache
    echo "Removed Github Personal Access Token"
    #read -p "Do you want to continue Save your Github Personal Access Token in cache (Y/n default: Y) ? " -n 1 -r
    #echo    # (optional) move to a new line
    #if [[ $REPLY =~ ^[Nn]$ ]]
    #then
    #    rm .githubpatcache
    #fi
fi

#Process Build Stacks
if [ "$nocachebuild_flag" = true ]; then
    if [ "$xbuildproduction_flag" = true ]; then
        docker compose -f docker-compose.yml -f docker-compose.prod.yml build --force-rm --no-cache
        docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
    else
        docker compose -f docker-compose.yml -f docker-compose.dev.yml build --force-rm --no-cache
        docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
    fi   
else
    if [ "$xbuildproduction_flag" = true ]; then
        docker compose -f docker-compose.yml -f docker-compose.prod.yml build --force-rm
        docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
    else
        docker compose -f docker-compose.yml -f docker-compose.dev.yml build --force-rm
        docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
    fi
fi

#Database Sync from Production
if [ "$databasesync_flag" = true ]; then
    while ! docker exec ${COMPOSE_PROJECT_NAME}_db mysqladmin --user=${DB_USERNAME} --password=${DB_PASSWORD} --host "127.0.0.1" ping --silent &> /dev/null ; do
        echo "Waiting for database connection..."
        sleep 2
    done

    docker exec -it ${COMPOSE_PROJECT_NAME}_db sh -c "apt update -qq -y && apt install -y sshpass rsync"

    #sshpass -p 'LCFRt_2013' ssh root@nhathuoclongchau.com -o StrictHostKeyChecking=no -p 22218 -R 3307:localhost:3306 'mysqldump -uroot -prootpassworddefault --all-databases | mysql --host=127.0.0.1 --port=3307 -uroot -prootpassworddefault'
    docker exec -it ${COMPOSE_PROJECT_NAME}_db sh -c "mysql -u${DB_USERNAME} -p${DB_PASSWORD} -e 'CREATE DATABASE ${DB_DATABASE} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci'"
    docker exec -it ${COMPOSE_PROJECT_NAME}_db sh -c "sshpass -p '${SSH_REMOTE_SERVER_PASSWORD}' ssh ${SSH_REMOTE_SERVER_USER}@${SSH_REMOTE_SERVER} -o StrictHostKeyChecking=no -p 22218 -R 3307:localhost:3306 'mysqldump -u${DB_USERNAME} -p${DB_PASSWORD} --add-drop-table -B ${DB_DATABASE} | mysql --host=127.0.0.1 --port=3307 -u${DB_USERNAME} -p${DB_PASSWORD} -B ${DB_DATABASE}'"
fi

#Sync Resources
if [ "$syncresources_flag" = true ]; then
    docker exec -it ${COMPOSE_PROJECT_NAME}_app sshpass -p '${SSH_REMOTE_SERVER_PASSWORD}' rsync -chavzP -e "ssh -o StrictHostKeyChecking=no -p 22218" ${SSH_REMOTE_SERVER_USER}@${SSH_REMOTE_SERVER}:/var/www/html/public/ /var/www/html/public/
fi

#Install composer package and npm package
if [ "$packageinstall_flag" = true ]; then
    docker exec -it ${COMPOSE_PROJECT_NAME}_app npm install
fi
