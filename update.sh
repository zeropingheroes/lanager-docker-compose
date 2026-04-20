#!/bin/bash

set -e

echo "Clearing Laravel caches"
docker exec -it lanager php artisan cache:clear
docker exec -it lanager php artisan clear-compiled
docker exec -it lanager php artisan config:clear
docker exec -it lanager php artisan optimize:clear
docker exec -it lanager php artisan route:clear
docker exec -it lanager php artisan view:clear

echo "Stopping containers"
docker compose down

echo "Updating Docker image zeropingheroes/lanager:stable"
docker pull zeropingheroes/lanager:stable

echo "Restarting containers and waiting for them all to be healthy"
docker compose up --detach --wait

echo "Running migrations"
docker exec -it lanager php artisan migrate
