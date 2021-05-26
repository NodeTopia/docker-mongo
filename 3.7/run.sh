#!/bin/bash
set -m

if [ "$STANDALONE" == "yes" ]; then
    mongodb_cmd="mongod --storageEngine $STORAGE_ENGINE --wiredTigerCacheSizeGB $CACHE_MEMORY_AVAILABLE --auth --port 27017"

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
    mongodb_cmd="mongod --storageEngine $STORAGE_ENGINE --wiredTigerCacheSizeGB $CACHE_MEMORY_AVAILABLE --auth"

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

    mongodb_cmd="$mongodb_cmd --port 27017 --shardsvr --replSet $REPLSET"
    $mongodb_cmd &
fi

if [ "$CONFIGSVR" != "" ]; then
    mongodb_cmd="mongod --storageEngine $STORAGE_ENGINE --wiredTigerCacheSizeGB $CACHE_MEMORY_AVAILABLE --auth"

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
    mongodb_cmd="$mongodb_cmd --port 27017 --replSet $CONFIGSVR"
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
    mongodb_cmd="mongodump --host $MONGODB_HOST --username $MONGODB_USER --password $MONGODB_PASS -d $MONGODB_DB --gzip --archive=-"
    mc_cmd="mc --config-folder /tmp pipe s3/$ARCHIVE_UPLOAD_PATH"

    $mongodb_cmd | $mc_cmd&
fi

if [ "$MONGORESTORE" != "" ]; then
    mongodb_cmd="mongorestore --host $MONGODB_HOST --username $MONGODB_USER --password $MONGODB_PASS -d $MONGODB_DB --drop --gzip --archive"
    mc_cmd="mc --config-folder /tmp cat s3/$ARCHIVE_PATH"

    $mc_cmd | $mongodb_cmd&
fi




fg
