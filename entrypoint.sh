#!/bin/sh
set -e

if [ ! -f "/config/localbckup.yaml" ]; then
    /usr/local/bin/confd -backend="env" -confdir="/etc/confd" -onetime  --log-level=debug
fi

exec "$@"
