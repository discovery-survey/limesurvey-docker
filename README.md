
This is a fork of https://github.com/adamzammit/limesurvey-docker

Origin files are located in the `origin` directory and are mostly used to track consistency with the main project.

There is no `ci` because it is used very rarely, so if you need to update something do it manually and don't forget add changes here.


The main difference with `origin` is `docker-custom-entrypoint.sh` which is used to start and project configuration.

If you need to update default parameters look at previous commits too see how it was done.


### TEST EMAIL
```shell
powershell -ExecutionPolicy Bypass -File .\smtp-test.ps1
```
