#!/usr/bin/env bash

if [[ -z "$1" ]] ; then

    echo "WARNING: This will delete all database data!"

    read -p "Do you wish to continue? " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit
    fi

fi

APP_CONTAINER_NAME="lanager"

if [ "$( docker container inspect -f '{{.State.Status}}' $APP_CONTAINER_NAME )" != "running" ]; then
    echo "Error: Container \"$APP_CONTAINER_NAME\" is not running"
    exit 1;
fi

if ! docker exec "$APP_CONTAINER_NAME" test -d features; then
    echo "Error: \"features\" folder not accessible by "$APP_CONTAINER_NAME" container. Please follow the development environment setup steps."
    exit 1
fi

echo "Changing APP_ENV to \"testing\""
export APP_ENV="testing"

echo "Setting Behat & Mink configuration"
export BEHAT_PARAMS='{"extensions" : {"Behat\\MinkExtension" : {"base_url" : "http://localhost:8000/"}}}'

echo "Reloading containers"
docker-compose up --detach

echo "Starting Laravel's built-in webserver in the background"
docker exec --detach "$APP_CONTAINER_NAME" php artisan serve

echo "Running Behat tests"
docker exec -it "$APP_CONTAINER_NAME" vendor/bin/behat "$@"

echo "Resetting APP_ENV and BEHAT_PARAMS to default value"
unset APP_ENV
unset BEHAT_PARAMS

echo "Reloading containers"
docker-compose up --detach
