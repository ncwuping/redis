#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
# or first arg is `something.conf`
if [ "${1#-}" != "$1" ] || [ "${1%.conf}" != "$1" ]; then
        set -- redis-server "$@"
fi

# allow the container to be started with `--user`
if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
        mv -f /usr/local/bin/redis.conf /data/
        chown -R redis:redis /data/redis.conf
        sed -E 's!^\s*#*\s*(cluster-announce-ip ).*!\1'${IPADDR:-$(tail -1 /etc/hosts | awk '{ print $1 }')}'!' -i /data/redis.conf
        sed -E 's!^\s*#*\s*(cluster-announce-port ).*!\16379!' -i /data/redis.conf

        mv -f /usr/local/bin/sentinel.conf /data/
        chown -R redis:redis /data/sentinel.conf
        {
                echo ''
                echo 'sentinel announce-ip' ${IPADDR:-$(tail -1 /etc/hosts | awk '{ print $1 }')}
                echo 'sentinel announce-port 26379'
                echo ''
                echo 'sentinel monitor shard1-master' ${SHARD1_MASTER_IP} ${SHARD1_MASTER_PORT} '2'
                echo 'sentinel monitor shard2-master' ${SHARD2_MASTER_IP} ${SHARD2_MASTER_PORT} '2'
                echo 'sentinel monitor shard3-master' ${SHARD3_MASTER_IP} ${SHARD3_MASTER_PORT} '2'
        } >> /data/sentinel.conf

        find . \! -user redis -exec chown redis '{}' +
        exec su-exec redis "$0" "$@"
fi

exec "$@"
