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

dockerLibrary=walmartlabs

source ${BASE_DIR}/.dev_config.props

if [ -s "$concordVersion" ]; then
    echo "Please specify concordVersion in .dev_config.props"
    exit 1;
fi
echo "concordVersion: ${concordVersion}"

CONCORD_CFG_FILE=${BASE_DIR}/dev/server.conf

echo "CONCORD_CFG_FILE: ${CONCORD_CFG_FILE}"

# get current agents number (locally)
agentCount=$(docker ps --all --format "{{.Names}}" | grep -c ${agentName})
printf -v agentCustomName "${agentName}-%02d" $((agentCount + 1))

# Start Concord Agent
docker run -d \
    --restart unless-stopped \
    --name ${agentCustomName} \
    --link ${serverName} \
    --link dind \
    -v ${DEV_DIR}/tmp:/tmp \
    -v "${HOME}/.m2/repository:/home/concord/.m2/repository" \
    -v "${BASE_DIR}/maven.json:/opt/concord/conf/maven.json:ro" \
    -e 'CONCORD_MAVEN_CFG=/opt/concord/conf/maven.json' \
    -e 'CONCORD_DOCKER_LOCAL_MODE=false' \
    -e "SERVER_API_BASE_URL=http://${serverName}:8001" \
    -e "SERVER_WEBSOCKET_URL=ws://${serverName}:8001/websocket" \
    ${dockerLibrary}/concord-agent:${concordVersion}
