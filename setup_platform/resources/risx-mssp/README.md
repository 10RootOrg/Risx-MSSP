# REQUIRED FILES

This files should be created/modified by the user and contain proper values *before* startup script is started

## Secret files:
* `env.DEHASHED_U.secret`
* `env.LEAKCHECK_API_KEY.secret`
* `shoresh.passwd`

## Configuration files:
* `environment.sh`
* `mssp_config.json.envsubst`

# MySQL database configuration

Any MySQL commands could be added to `permissions.sql` script, including database creation and initialization. 
This file is used during a build stage and requires a docker image rebuild for enabling modifications. 

# How to use

* Create `shoresh.passwd` file with a secure password. For example, `apg` could be used: ```$ apg -m 16 -n 1 > shoresh.passwd```
* Run `docker-compose up`, images would be built and started
