FROM adamzammit/limesurvey:6.15.23

COPY docker-custom-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
