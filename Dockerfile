FROM redis:6.0.16-alpine3.14

ENV REDIS_BASE_URL https://github.com/redis/redis/raw

RUN wget ${REDIS_BASE_URL}/${REDIS_VERSION}/redis.conf \
 && sed -E 's!^\s*(bind 127\.0\.0\.1)!#\1!' -i redis.conf \
 && sed -E 's!^\s*#*(protected-mode )yes!\1no!' -i redis.conf \
 && sed -E 's!^\s*#*(dir ).*!\1\/var\/lib\/redis!' -i redis.conf \
 && sed -E 's!^\s*#*\s*(maxmemory ).+!\1100m!' -i redis.conf \
 && sed -E 's!^\s*#*\s*(maxmemory-policy ).+!\1allkeys-lru!'  -i redis.conf \
 && sed -E 's!^\s*#*(no-appendfsync-on-rewrite )no!\1yes!' -i redis.conf \
 && sed -E 's!^\s*#*\s*(cluster-enabled .*)!\1!' -i redis.conf \
 && sed -E 's!^\s*#*\s*(cluster-config-file nodes)-[[:digit:]]+(\.conf)!\1\2!' -i redis.conf \
 && sed -E 's!^\s*#*\s*(cluster-node-timeout [[:digit:]]+)!\1!' -i redis.conf \
 && sed -E 's!^\s*#*\s*(cluster-migration-barrier [[:digit:]]+)!\1!' -i redis.conf \
 && sed -E 's!^\s*(latency-monitor-threshold [[:digit:]]+)!#\1!' -i redis.conf \
 && mv -f redis.conf /usr/local/bin/; \
 \
    wget ${REDIS_BASE_URL}/${REDIS_VERSION}/sentinel.conf \
 && sed -E 's!^\s*#*\s*(protected-mode no)!\1!' -i sentinel.conf \
 && sed -E 's!^\s*(sentinel monitor mymaster 127\.0\.0\.1 6379 2)!#\1!' -i sentinel.conf \
 && sed -E 's!^\s*(sentinel down-after-milliseconds mymaster 30000)!#\1!' -i sentinel.conf \
 && sed -E 's!^\s*(sentinel parallel-syncs mymaster 1)!#\1!' -i sentinel.conf \
 && sed -E 's!^\s*(sentinel failover-timeout mymaster 180000)!#\1!' -i sentinel.conf \
 && { \
    echo ''; \
    echo '# By default Redis shows an ASCII art logo only when started to log to the'; \
    echo '# standard output and if the standard output is a TTY. Basically this means'; \
    echo '# that normally a logo is displayed only in interactive sessions.'; \
    echo '#'; \
    echo '# However it is possible to force the pre-4.0 behavior and always show a'; \
    echo '# ASCII art logo in startup logs by setting the following option to yes.'; \
    echo 'always-show-logo yes'; \
    } >> sentinel.conf \
 && mv -f sentinel.conf /usr/local/bin/

COPY docker-entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh
