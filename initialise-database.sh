#!/usr/bin/env bash

echo "WARNING: This will delete any data in the LANager database"

read -p "Do you wish to continue? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit
fi

APP_CONTAINER_NAME="lanager"

# Create the database structure
docker exec -it $APP_CONTAINER_NAME php artisan migrate:fresh --force

# Fill the database with the required base data
docker exec -it $APP_CONTAINER_NAME php artisan db:seed --force --class=Database\\Seeders\\DatabaseSeeder

# Import Steam apps data from CSV file
docker exec -it $APP_CONTAINER_NAME php artisan lanager:import-steam-apps-csv
