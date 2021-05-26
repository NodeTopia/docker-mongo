#!/bin/bash
set -m

if [ "$KEYFILE" != ""  ]; then
   echo $KEYFILE > /mongodb-keyfile
fi

if [ "$STANDALONE" == "yes" ]; then
    mongodb_cmd="mongod --storageEngine $STORAGE_ENGINE --auth --port 27017 --bind_ip 0.0.0.0"

    if [ "$JOURNALING" == "no" ]; then
        mongodb_cmd="$mongodb_cmd --nojournal"
    fi

    if [ "$OPLOG_SIZE" != "" ]; then
        mongodb_cmd="$mongodb_cmd --oplogSize $OPLOG_SIZE"
    fi

    $mongodb_cmd &
    if [ "$AUTH" == "yes" ]; then
        RET=1
        while [[ RET -ne 0 ]]; do
            echo "=> Waiting for confirmation of MongoDB service startup"
            sleep 5
            mongo admin --eval "help" >/dev/null 2>&1
            RET=$?
        done
        mongo admin --port 27017 --eval "db.createUser({user: '$MONGODB_USER', pwd: '$MONGODB_PASS', roles:[{role:'root',db:'admin'}]});"
    fi
fi

if [ "$REPLSET" != "" ]; then
    mongodb_cmd="mongod --storageEngine $STORAGE_ENGINE --auth"

    if [ "$JOURNALING" == "no" ]; then
        mongodb_cmd="$mongodb_cmd --nojournal"
    fi

    if [ "$OPLOG_SIZE" != "" ]; then
        mongodb_cmd="$mongodb_cmd --oplogSize $OPLOG_SIZE"
    fi

    mongodb_cmd="$mongodb_cmd --keyFile /mongodb-keyfile"


    if [ "$AUTH" == "yes" ]; then

        $mongodb_cmd  --port 17017 &
        RET=1
        while [[ RET -ne 0 ]]; do
            echo "=> Waiting for confirmation of MongoDB service startup"
            sleep 5
            mongo admin --port 17017 --eval "help" >/dev/null 2>&1
            RET=$?
        done

        mongo admin --port 17017 --eval "db.createUser({user: '$MONGODB_USER', pwd: '$MONGODB_PASS', roles:[{role:'root',db:'admin'}]});"
        mongo admin --port 17017 -u $MONGODB_USER -p $MONGODB_PASS  --eval "db.getSiblingDB('admin').shutdownServer();"
    fi

    mongodb_cmd="$mongodb_cmd --port 27017 --bind_ip 0.0.0.0 --shardsvr --replSet $REPLSET"
    $mongodb_cmd &
fi

if [ "$CONFIGSVR" != "" ]; then
    mongodb_cmd="mongod --storageEngine $STORAGE_ENGINE --auth"

    if [ "$JOURNALING" == "no" ]; then
        mongodb_cmd="$mongodb_cmd --nojournal"
    fi

    if [ "$OPLOG_SIZE" != "" ]; then
        mongodb_cmd="$mongodb_cmd --oplogSize $OPLOG_SIZE"
    fi

    mongodb_cmd="$mongodb_cmd --port 27017 --configsvr --keyFile /mongodb-keyfile --dbpath /data/db"



    if [ "$AUTH" == "yes" ]; then

        $mongodb_cmd --port 17017 &
        RET=1
        while [[ RET -ne 0 ]]; do
            echo "=> Waiting for confirmation of MongoDB service startup"
            sleep 5
            mongo admin --port 17017 --eval "help" >/dev/null 2>&1
            RET=$?
        done

        mongo admin --port 17017 --eval "db.createUser({user: '$MONGODB_USER', pwd: '$MONGODB_PASS', roles:[{role:'root',db:'admin'}]});"
        mongo admin --port 17017 -u $MONGODB_USER -p $MONGODB_PASS  --eval "db.getSiblingDB('admin').shutdownServer();"
    fi
    mongodb_cmd="$mongodb_cmd --port 27017 --bind_ip 0.0.0.0 --replSet $CONFIGSVR"
    $mongodb_cmd &
fi

if [ "$MONGOS" != "" ]; then
    mongodb_cmd="mongos"

    mongodb_cmd="$mongodb_cmd --configdb $MONGOS --keyFile /mongodb-keyfile"

    $mongodb_cmd &
    if [ "$AUTH" == "yes" ]; then
        RET=1
        while [[ RET -ne 0 ]]; do
            echo "=> Waiting for confirmation of MongoDB service startup"
            sleep 5
            mongo admin --eval "help" >/dev/null 2>&1
            RET=$?
        done
        mongo admin --eval "db.createUser({user: '$MONGODB_USER', pwd: '$MONGODB_PASS', roles:[{role:'root',db:'admin'}]});"
    fi
fi

if [ "$MONGODUMP" != "" ]; then
   mongodump --uri $MONGODB_URI --gzip --archive=/tmp/dump.archive

   echo "mongodump --uri $MONGODB_URI --gzip --archive=/tmp/dump.archive"


    mc_cmd="curl -v --upload-file /tmp/dump.archive $ARCHIVE_PATH "
	$mc_cmd &
fi

if [ "$MONGORESTORE" != "" ]; then
    wget $ARCHIVE_PATH -O /tmp/dump.archive 2> /dev/null
    mongodb_cmd="mongorestore --uri $MONGODB_URI --drop --gzip --archive=/tmp/dump.archive"
	
    $mongodb_cmd&
fi




fg
