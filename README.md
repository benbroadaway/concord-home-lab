# concord-home-lab
Quick and dirty and not-super secure script to whip up a [Concord](https://concord.walmartlabs.com) environment for testing

## Requirements
* Docker CE
* Linux or Mac OS
* 4GB memory
* Docker Hub access (or somehow get OpenLDAP and Postgres)
* Concord Docker Images (see [Where to get Concord Images](#where-to-get-concord-images))

## Set up config
Create a file called `.dev_config.props` in the root folder. Customize the variables with values you want. 

```properties
ldapUser=my-ldap-username
ldapPass=my-ldap-password
oldapAdminPass=admin-password
dbPass=database-password
concordVersion=1.12.0
consolePort=8080   # docker-published port
```

## Run the script
```
$ ./start-concord.sh
```
```
concordVersion: 1.12.0
CONCORD_CFG_FILE: /home/ubuntu/Projects/concord-dev/dev/server.conf
Deleting any existing containers...
concord-console
concord-agent
dind
concord-server
concord-database
concord-oldap
5fbe799be92e6b2ceae8c21c087177fef169c1d1e66caac8d2c7d8ca87873f73
da1404137c8f93e88fc94ce592e8cabf6060d46bdda5b48da611f3994815c43c
Waiting for LDAP server to start
adding new entry "cn=my-ldap-username,dc=example,dc=org"

9ba8044a84bd2ab5456f12a018a67bb7ab4d9b57ba68effce2c74224d39994f7
Waiting for server to start..............
c319df943cc073d24dc4e60d219effa68d66634ef461d9ea0cc84f021df8c57d
98a624fc2922f4deac47d7b20783fd5d82bdcec2821017f79d589d410f6d5dd4
16c5df12a5e24a6636e9fdc96b4ae55690a4821a4d35cf16c538127469cd6326
```

## Gotchas
I haven't finished externalizing things 100%. If you want to change the names of the Docker instances, then you have to dig through and change the referenced hostnames (e.g. `concord-server` in `start-concord.sh` and `app.conf`). Search the project for each container name and replace with the new name.

## Where to get Concord Images
They're not on Docker Hub yet, but you can [build them from source](https://github.com/walmartlabs/concord#building).

## Or how to build them according to me
Check out a release tag.
```
$ git fetch --all --tags --prune
$ git checkout tags/1.12.0 -b concord-1.12.0
```
```
Switched to a new branch 'concord-1.12.0'
```
Build and pray
```
$ ./mvnw clean install -DskipTests
```
Now build with Docker images and pray harder
```
$ ./mvnw clean install -DskipTests -Pdocker
```
See what you have now
```
$ docker images ls | grep concord
```
```
walmartlabs/concord-console   1.12.0              b9469d23fbd9        2 minutes ago       572MB
walmartlabs/concord-console   latest              b9469d23fbd9        2 minutes ago       572MB
walmartlabs/concord-server    1.12.0              02b402aa5fe2        3 minutes ago       569MB
walmartlabs/concord-server    latest              02b402aa5fe2        3 minutes ago       569MB
walmartlabs/concord-agent     1.12.0              aae56d25c75e        3 minutes ago       895MB
walmartlabs/concord-agent     latest              aae56d25c75e        3 minutes ago       895MB
walmartlabs/concord-ansible   1.12.0              205f05035f3c        3 minutes ago       750MB
walmartlabs/concord-ansible   latest              205f05035f3c        3 minutes ago       750MB
walmartlabs/concord-base      1.12.0              ca619feebee1        4 minutes ago       528MB
walmartlabs/concord-base      latest              ca619feebee1        4 minutes ago       528MB
```

### Build Docker Imges with different package name
```
$ ./mvnw clean install -DskipTests -Pdocker -Ddocker.namespace=benbroadaway
```
```
benbroadaway/concord-console   1.12.0                  f29b342595a3        14 seconds ago      635MB
benbroadaway/concord-console   latest                  f29b342595a3        14 seconds ago      635MB
benbroadaway/concord-server    1.12.0                  8a28d9e25af6        48 seconds ago      631MB
benbroadaway/concord-server    latest                  8a28d9e25af6        48 seconds ago      631MB
benbroadaway/concord-agent     1.12.0                  8cc05776d5b9        51 seconds ago      958MB
benbroadaway/concord-agent     latest                  8cc05776d5b9        51 seconds ago      958MB
benbroadaway/concord-ansible   1.12.0                  1509b8a47116        2 minutes ago       813MB
benbroadaway/concord-ansible   latest                  1509b8a47116        2 minutes ago       813MB
benbroadaway/concord-base      1.12.0                  868ccd94194d        3 minutes ago       590MB
benbroadaway/concord-base      latest                  868ccd94194d        3 minutes ago       590MB
```

## Kind of common build problems
### User can't run `docker` without sudo
Don't forget to do the [post-install tasks](https://docs.docker.com/install/linux/linux-postinstall/) for Linux