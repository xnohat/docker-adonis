# We'll use the Node slim image as a base cos it's light and nice
FROM node:16

WORKDIR /usr/src/app

# install all the dependencies and enable PHP modules
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
      sudo \
      procps \
      htop \
      nload \
      nano \
      git \
      curl \
      gnupg \
      wget \
      zip \
      unzip \
      sshpass \
      rsync \
      openssh-server \
      ssh \
      openssl libssl-dev \
      supervisor \
      cron \
      locales

# Copy source of app to image
COPY --chown=node:node ./src ./

# Copy package.json & package-lock.json
#COPY ./src/package*.json ./

# Copy preconfig app .env
COPY ./etc/app/.env .env

RUN mkdir -p /usr/src/app/node_modules

# Edit .env file
# Replace HOST variable to 0.0.0.0 in .env for allow external access
#RUN sed -i 's/^HOST=127.0.0.1/HOST=0.0.0.0/g' .env

# Add node_modules to the envionmental path variable so we can run binaries easily
ENV PATH /usr/src/app/node_modules/.bin:$PATH

USER root

# Install the good ol' NPM modules and get Adonis CLI in the game
RUN npm install --no-optional

# Install adonis-scheduler
RUN npm install adonis5-scheduler
RUN node ace invoke adonis5-scheduler

# Compile adonisjs
RUN mkdir -p ./build
RUN node ace build --production
RUN cd ./build && npm ci --production
RUN yes | cp -rf .env build/.env

# We'll use PM2 as a process manager for our Node server
#RUN npm install -g pm2

COPY ./etc/app/ecosystem.config.js ecosystem.config.js

# Modify AdonisJS server.js to process SIGNT (Ctrl-C) to terminate node process. Notes: Multiline echo command must extract same below with quote and \ at start & end of string
#RUN echo -e "\
#\n\
#// Without it process won't die in container \n\
#process.on('SIGINT', () => { \n\
#  server.kill(10) \n\
#}) \
#" >> server.ts

# Let all incoming connections use the port below
EXPOSE 3333

CMD node ace serve --watch
#CMD pm2-runtime start ecosystem.config.js