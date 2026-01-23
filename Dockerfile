FROM adamzammit/limesurvey:6.16.4

COPY docker-custom-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
