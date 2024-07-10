FROM adamzammit/limesurvey:6.4.5

COPY docker-custom-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
