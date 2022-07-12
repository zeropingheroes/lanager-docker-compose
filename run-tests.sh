#!/usr/bin/env bash

if [[ $* != *--skip-warnings* ]]; then

    echo "WARNING: This will delete all database data!"

    read -p "Do you wish to continue? " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit
    fi

fi

CONTAINER_NAME="app"

if [ "$( docker container inspect -f '{{.State.Status}}' $CONTAINER_NAME )" != "running" ]; then
    echo "Error: Container \"$CONTAINER_NAME\" is not running"
    exit 1;
fi

if ! docker exec "$CONTAINER_NAME" test -d features; then
    echo "Error: \"features\" folder not accessible by "$CONTAINER_NAME" container. Please follow the development environment setup steps."
    exit 1
fi

echo "Changing APP_ENV to \"testing\""
export APP_ENV="testing"

echo "Reloading containers"
docker-compose up --detach

echo "Starting Laravel's built-in webserver in the background"
docker exec --detach "$CONTAINER_NAME" php artisan serve

echo "Running Behat tests"
docker exec -it "$CONTAINER_NAME" sh -c "export BEHAT_PARAMS='{\"extensions\" : {\"Behat\\\\MinkExtension\" : {\"base_url\" : \"http://localhost:8000/\"}}}' && vendor/bin/behat --format progress"

echo "Resetting APP_ENV to default value"
unset APP_ENV

echo "Reloading containers"
docker-compose up --detach
