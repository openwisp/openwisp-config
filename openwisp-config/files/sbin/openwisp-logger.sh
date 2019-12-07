#!/bin/sh

LOG_FILE="/var/log/openwisp/log"

function log()
    ERR_MSG=$1
    TAG=$2
    PRIO=$2
    echo $(logger -s "$ERR_MSG" -t $TAG -p daemon.info $PRIO) >> $LOG_FILE