#!/bin/bash

set -e

echo "Updating Git repo zeropingheroes/lanager-docker-compose"
git pull

echo "Updating Docker image zeropingheroes/lanager:develop"
docker pull zeropingheroes/lanager:develop

echo "Restarting containers"
docker-compose up --detach
