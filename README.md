# docker-adonis
***docker environment for develop and production run AdonisJS***

Clone this git project to start your own AdonisJS Development Environment by Docker
```
git clone https://github.com/xnohat/docker-adonis
```

**Folders structure**
```
/
-/etc : all config files of stack
 --/app : all specific app config files
  --/.env.dev : .env file of AdonisJS app but for DEV environment
  --/.env.prod : .env file of AdonisJS app but for PROD environment
 --/home/user/ : mount point of /home/<user> inside docker container _app for dev enviroment
-/src : source code of app
-/.env : .env file of Docker Compose
-/build.sh : build script tool
```

./build.sh parameters
```
docker-adonis$ ./build.sh -h
usage: ./build.sh
    [-h] Help
    [-r] Remove saved github personal access token
    [-g] Git new source update
    [-c] Clone Source instead Pull
    [-i] Init New Project in folder src
    [-d] Database Sync from Production
    [-p] Packages Install (npm)
    [-n] No cache layers when build
    [-x] xBuild app image and stacks for PRODUCTION (default is build for Dev)
```

Example use:

1. **Start new project**
```
./build.sh -i -p
```
Follow screen guide to Init new AdonisJS project in ./src

2. **Pull new updates of project from Git**
edit ./.env of docker compose for specify git repo and branch to pull\
GIT_REPO\
GIT_BRANCH
```
./build.sh -g -p
```
notes: if you need "clone" project instead "pull" , use -g -c params
```
./build.sh -g -c -p
```

3. **Build PRODUCTION image and stacks (it's mean build target: prod)**
```
./build.sh -x
```
notes: 
- file **./etc/app/.env.dev** and **./etc/app/.env.prod** are **.env** files of AdonisJS app but for DEV and PROD environment, change them for specific target build environment you need
- Default target environment of ./build.sh is DEV
- DEV environment will map current host user to docker container, this method will allow you easy to edit code in ./src without chown every times
- When you ssh to inside docker _app you will have right of current host user, use sudo for root privilege
- PROD environment will use root user as docker default

4. **Run Schedule task by Supervisord and Cron**
- Schedule provide by package adonis5-scheduler preinstalled\
- Schedule will auto run on Production Enviroment by docker service Supervisord\
- On DEV Environment you must SSH inside docker container _app and manually run command below to run scheduled task
```
node ace scheduler:run
```

**Access**\
Your website will access on port 80 (through Nginx as reverse proxy):\
http://localhost \
Your nodejs website cat directly access on port 3333:\
http://localhost:3333 

Read docker-compose.yml, Dockerfile, and ./build.sh source for more information
