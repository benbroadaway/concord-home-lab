#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
DEV_DIR=${BASE_DIR}/dev
defaultVars=${BASE_DIR}/default_vars.yml
mkdir -p ${DEV_DIR}/tmp
chmod 0777 ${DEV_DIR}/tmp

ldapUser=
ldapPass=
dbPass=
appPass=
consolePort=

dbName=concord-database
oldapName=concord-oldap
serverName=concord-server
agentName=concord-agent
consoleName=concord-console

source ${BASE_DIR}/.dev_config.props

if [ -s "$concordVersion" ]; then
    echo "Please specify concordVersion in .dev_config.props"
    exit 1;
fi
echo "concordVersion: ${concordVersion}"

if [ -z "$CONCORD_CFG_FILE" ]; then
    CONCORD_CFG_FILE="${BASE_DIR}/server.conf"
fi

cp ${CONCORD_CFG_FILE} ${BASE_DIR}/dev/server.conf
CONCORD_CFG_FILE=${BASE_DIR}/dev/server.conf

sed -e "s/\(appPassword\)[ =]\{0,\}.\{0,\}/\1 = \"${dbPass}\"/g" \
    -e "s/\(inventoryPassword\)[ =]\{0,\}.\{0,\}/\1 = \"${dbPass}\"/g" \
    -e "s/\(serverPassword\)[ =]\{0,\}.\{0,\}/\1 = \"$(echo ${dbPass} | base64)\"/g" \
    -e "s/\(secretStoreSalt\)[ =]\{0,\}.\{0,\}/\1 = \"$(echo ${dbPass} | base64)\"/g" \
    -e "s/\(projectSecretSalt\)[ =]\{0,\}.\{0,\}/\1 = \"$(echo ${dbPass} | base64)\"/g" \
    -e "s/\(systemPassword\)[ =]\{0,\}.\{0,\}/\1 = \"${oldapAdminPass}\"/g" \
    ${CONCORD_CFG_FILE} > ${CONCORD_CFG_FILE}.tmp
mv ${CONCORD_CFG_FILE}.tmp ${CONCORD_CFG_FILE}

echo "CONCORD_CFG_FILE: ${CONCORD_CFG_FILE}"

echo "Deleting any existing containers..."
docker rm -f ${consoleName} ${agentName} dind ${serverName} ${dbName} ${oldapName} 2>/dev/null

# Start Postgres DB
docker run -d \
    --name ${dbName} \
    -e "POSTGRES_PASSWORD=${dbPass}" \
    -e 'PGDATA=/var/lib/postgresql/data/pgdata' \
    --mount source=concordDB,target=/var/lib/postgresql/data \
    -p 5432:5432 \
    postgres:10.7-alpine
  
# start OpenLDAP
docker run -d \
    -e LDAP_ADMIN_PASSWORD=${oldapAdminPass} \
    --name ${oldapName} \
    osixia/openldap:1.2.3

echo "Waiting for LDAP server to start"
sleep 10
if [ $(docker exec -i ${oldapName}  ldapsearch -x -D "cn=admin,dc=example,dc=org" -w ${oldapAdminPass} -LLL -b "dc=example,dc=org" cn=* cn | grep ${ldapUser} | wc -l) -ge 2 ]; then
    echo "${ldapUser} already exists in ldap"
else
    # inject user info
    echo "dn: cn=${ldapUser},dc=example,dc=org" > ${BASE_DIR}/dev/new_user.ldif
    echo "cn: ${ldapUser}" >> ${BASE_DIR}/dev/new_user.ldif
    echo "objectClass: top" >> ${BASE_DIR}/dev/new_user.ldif
    echo "objectClass: organizationalRole" >> ${BASE_DIR}/dev/new_user.ldif
    echo "objectClass: simpleSecurityObject" >> ${BASE_DIR}/dev/new_user.ldif
    echo "objectClass: mailAccount" >> ${BASE_DIR}/dev/new_user.ldif
    echo "userPassword: $(docker exec ${oldapName}  slappasswd -h {SSHA} -s ${ldapPass})" >> ${BASE_DIR}/dev/new_user.ldif
    echo "mail: ${ldapUser}@example.org" >> ${BASE_DIR}/dev/new_user.ldif
    cat ${BASE_DIR}/dev/new_user.ldif | docker exec -i ${oldapName} ldapadd -x -D "cn=admin,dc=example,dc=org" -w ${oldapAdminPass}
fi

# Start Concord Server
docker run -d \
    --link ${dbName} \
    --link ${oldapName} \
    --name ${serverName} \
    -p 8001:8001 \
    -v "${DEV_DIR}/tmp:/tmp" \
    -v "${CONCORD_CFG_FILE}:/opt/concord/conf/server.conf:ro" \
    -v "${defaultVars}:/opt/concord/conf/default_vars.yml:ro" \
    -v "${HOME}/.m2/repository:/home/concord/.m2/repository" \
    -v "${BASE_DIR}/maven.json:/opt/concord/conf/maven.json:ro" \
    -e 'CONCORD_MAVEN_CFG=/opt/concord/conf/maven.json' \
    -e 'CONCORD_CFG_FILE=/opt/concord/conf/server.conf' \
    -e 'CONCORD_ENV=home-lab' \
    -e "DB_URL=jdbc:postgresql://${dbName}:5432/postgres" \
    walmartlabs/concord-server:${concordVersion}

# wait for server to start
echo -n "Waiting for server to start"
until $(curl --output /dev/null --silent --head --fail "http://localhost:8001/api/v1/server/ping"); do
    printf "."
    sleep 1
done
printf ".\n"


# Start Docker-in-Docker (DIND)
docker run -d \
    --privileged \
    --name dind \
    --volume ${DEV_DIR}/tmp:/tmp \
    'docker:18.09-dind'

# Start Concord Agent
docker run -d \
    --name ${agentName} \
    --link ${serverName} \
    --link dind \
    -v ${DEV_DIR}/tmp:/tmp \
    -v "${HOME}/.m2/repository:/home/concord/.m2/repository" \
    -v "${BASE_DIR}/maven.json:/opt/concord/conf/maven.json:ro" \
    -e 'CONCORD_MAVEN_CFG=/opt/concord/conf/maven.json' \
    -e 'CONCORD_DOCKER_LOCAL_MODE=false' \
    -e "SERVER_API_BASE_URL=http://${serverName}:8001" \
    -e "SERVER_WEBSOCKET_URL=ws://${serverName}:8001/websocket" \
    walmartlabs/concord-agent:${concordVersion}


# Start Concord Console
docker run -d \
    --name ${consoleName} \
    --link ${serverName} \
    --publish "${consolePort}:8080" \
    --volume "${BASE_DIR}/dev/console/logs:/opt/concord/logs" \
    --volume "${BASE_DIR}/app.conf:/opt/concord/console/nginx/app.conf" \
    walmartlabs/concord-console:${concordVersion}


sleep 5;








