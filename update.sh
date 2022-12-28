#!/bin/bash

set -e

echo "Clearing Laravel caches"
docker exec -it lanager php artisan cache:clear
docker exec -it lanager php artisan clear-compiled

echo "Stopping containers"
docker-compose down

echo "Updating Git repo zeropingheroes/lanager-docker-compose"
git pull

echo "Updating Docker image zeropingheroes/lanager:develop"
docker pull zeropingheroes/lanager:develop

echo "Restarting containers"
docker-compose up --detach
