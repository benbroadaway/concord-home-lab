#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

source "${BASE_DIR}/.dev_config.props"

json=$(
    curl -s -u ${ldapUser}:${ldapPass} \
      -H "Content-Type: application/json" \
      -d "{ \"username\": \"${ldapUser}\", \"name\": \"concord-api-key\" }" \
      "http://localhost:${consolePort}/api/v1/apikey"
    )
key=$(echo ${json} | sed -e 's/.*key" * : *"\(.[^"]*\)".*/\1/')
echo "Keep your API key secret for future use!"
echo "Here's your API key: ${key}"
