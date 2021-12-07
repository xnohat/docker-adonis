# docker-adonis
docker environment for develop AdonisJS

Clone this git project to start your own AdonisJS Development Environment by Docker
```
git clone https://github.com/xnohat/docker-adonis
```

folder structure
```
/
-/etc : all config files of stack
 --/app : all specific app config files
  --/.env : .env file of AdonisJS app
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
```

Example use:

1. Start new project
```
./build.sh -i
```
Follow screen guide to Init new AdonisJS project in ./src

2. Pull new updates of project from Git
edit ./.env of docker compose
GIT_REPO
GIT_BRANCH
```
./build.sh -g -p
```

Your development website will access on port 80 (through Nginx as reverse proxy):\
http://localhost \
Your nodejs website cat directly access on port 3333:\
http://localhost:3333 

Read docker-compose.yml, Dockerfile, and ./build.sh source for more information
