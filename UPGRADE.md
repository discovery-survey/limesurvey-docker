## How to upgrade
```shell
docker compose build --pull --no-cache limesurvey
docker compose up -d --force-recreate limesurvey
```

Then update files via an after-upgrade.sh script:

```shell
/after-upgrade.sh
```
