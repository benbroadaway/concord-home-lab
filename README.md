# concord-home-lab
Quick and dirty and not-super secure script to whip up a [Concord](https://concord.walmartlabs.com) environment for testing

## Requirements
* Docker CE
* Linux or Mac OS
* Docker Hub access (or somehow get OpenLDAP and Postgres)
* Concord Images (see [Where to get Concord Images](where-to-get-concord-images))

## Set up config
Create a file called `.dev_config.props` in the root folder. Customize the variables with values you want. 

```properties
ldapUser=basic-username
ldapPass=basic-password
oldapAdminPass=admin-password
dbPass=database-password
concordVersion=1.9.1-SNAPSHOT
consolePort=8080   # docker-published port
```

## Run the script
```
$ ./start-concord.sh
```

```
concordVersion: 1.9.1-SNAPSHOT
CONCORD_CFG_FILE: /home/ubuntu/Projects/concord-dev/dev/server.conf
Deleting any existing containers...
concord-console
concord-agent
concord-server
concord-database
concord-oldap
bdae9c22bd5603b5c2c32c1b209ed4bb3526f13b9aea04aca94356e29786b8f6
b5c2095af24d0d3c1f7c16a3e4f2f5b8f0da8c4dcdd478c20d0750ac39ba458e
Waiting for LDAP server to start
adding new entry "cn=basic-username,dc=example,dc=org"

fa0c553fbd5527b48263827faafe56db25b107d24a7f232dc55f4dd0b22febdc
Waiting for server to start..............
a35e43bad593751afef48d6b6cbbc07cd5ca1d76e897743235f0d389c42e0856
68e46d8fa6e2184f5a6fa9517b9e1b4bbcc0f291d96b4cb4e857b66fa2a5496e
```

## Gotchas
I haven't finished externalizing things 100%. If you want to change the names of the Docker instances, then you gotta dig through and change the refrenced hostnames (e.g. `concord-server` in `start-concord.sh` and `app.conf`)

## Where to get Concord Images
They're not on Docker Hub yet, but you can [build them from source](https://github.com/walmartlabs/concord#building).