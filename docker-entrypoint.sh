#!/bin/sh
set -e

[ -d /var/lib/redis ] && chown -R redis:redis /var/lib/redis

# first arg is `-f` or `--some-option`
# or first arg is `something.conf`
if [ "${1#-}" != "$1" ] || [ "${1%.conf}" != "$1" ]; then
        set -- redis-server "$@"
fi

# allow the container to be started with `--user`
if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
        mv -f /usr/local/bin/redis.conf /data/
        chown -R redis:redis /data/redis.conf
        sed -E 's!^\s*(port ).*!\1'${CLUSTER_ADVERTISE_PORT:-6379}'!' -i /data/redis.conf
        sed -E 's!^\s*(pidfile /var/run/redis_).*(\.pid)!\1'${CLUSTER_ADVERTISE_PORT:-6379}'\2!' -i /data/redis.conf
        sed -E 's!^\s*#*\s*(cluster-announce-ip ).*!\1'${CLUSTER_ADVERTISE_IP:-$( hostname -i )}'!' -i /data/redis.conf
        sed -E 's!^\s*#*\s*(cluster-announce-port ).*!\1'${CLUSTER_ADVERTISE_PORT:-6379}'!' -i /data/redis.conf
        sed -E 's!^\s*#*\s*(cluster-announce-bus-port ).*!\1'${CLUSTER_ADVERTISE_BUS_PORT:-6380}'!' -i /data/redis.conf
        if [ ! ${REQUIREPASS} = "" ]; then
          sed -E 's!^\s*#*\s*(masterauth ).*!\1'${MASTERAUTH}'!' -i /data/redis.conf
          sed -E 's!^\s*#*\s*(requirepass ).*!\1'${REQUIREPASS}'!' -i /data/redis.conf
        fi

        mv -f /usr/local/bin/sentinel.conf /data/
        sed -E 's!^\s*(port ).*!\1'${SENTINEL_ADVERTISE_PORT:-26379}'!' -i /data/sentinel.conf
        chown -R redis:redis /data/sentinel.conf
        {
                echo ''
                echo 'sentinel announce-ip' ${SENTINEL_ADVERTISE_IP:-$( hostname -i )}
                echo 'sentinel announce-port' ${SENTINEL_ADVERTISE_PORT:-26379}
                echo ''
                echo 'sentinel monitor shard1-master' ${SHARD1_MASTER_IP} ${SHARD1_MASTER_PORT} '2'
                echo 'sentinel monitor shard2-master' ${SHARD2_MASTER_IP} ${SHARD2_MASTER_PORT} '2'
                echo 'sentinel monitor shard3-master' ${SHARD3_MASTER_IP} ${SHARD3_MASTER_PORT} '2'
        } >> /data/sentinel.conf

        find . \! -user redis -exec chown redis '{}' +
        exec su-exec redis "$0" "$@"
fi

exec "$@"
