#!/bin/sh

DATADIR=/var/lib/graphite/whisper

if [ ! -d "$DATADIR" ];
then
    mkdir -p $DATADIR && chown -R carbon:carbon $DATADIR
fi

DATADIR_OWNER=$(stat -c '%U' "${DATADIR}")
if [ "x${DATADIR_OWNER}" != "xcarbon" ];
then
    chown -R carbon:carbon $DATADIR
fi

su-exec carbon /usr/bin/go-carbon -config=/etc/go-carbon/go-carbon.conf -daemon=false 2>&1