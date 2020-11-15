FROM node:14-alpine

WORKDIR /app
COPY *.js ./
COPY *.json ./

ENV WEBMONITOR_INTERVAL=300
ENV SENDGRID_API_KEY=__SET_ME__

ENTRYPOINT [ "node", "standalone.js" ]