FROM node:latest

WORKDIR /usr/src/app

COPY files/* /usr/src/app

ENV PM2_HOME=/tmp

RUN apt-get update &&\
    apt-get install -y iproute2 vim &&\
    npm install -r package.json &&\
    npm install -g pm2 &&\
    wget -O cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb &&\
    dpkg -i cloudflared.deb &&\
    rm -f cloudflared.deb &&\
    addgroup --gid 10014 choreo &&\
    adduser --disabled-password  --no-create-home --uid 10014 --ingroup choreo choreouser &&\
    usermod -aG sudo choreouser &&\
    chmod +x web.js entrypoint.sh &&\
    npm install -r package.json

USER 10014

ENTRYPOINT ["node", "server.js"]
