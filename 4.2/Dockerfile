#FROM arm64v8/ubuntu:18.04
FROM ubuntu:18.04

RUN apt-get update -y && apt-get install -y wget gnupg curl

RUN wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -

RUN echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list

RUN apt-get update -y && apt-get install -y mongodb-org

VOLUME /data/db

RUN mkdir -p /data/db /data/configdb \
	&& chown -R mongodb:mongodb /data/db /data/configdb
VOLUME /data/db /data/configdb

ENV AUTH yes
ENV STORAGE_ENGINE wiredTiger
ENV JOURNALING yes
ENV CACHE_MEMORY_AVAILABLE 1

RUN openssl rand -base64 756 > /mongodb-keyfile
RUN chmod 400 /mongodb-keyfile


ADD run.sh /run.sh
RUN chown -R mongodb:mongodb /run.sh

EXPOSE 27017

CMD ["/run.sh"]