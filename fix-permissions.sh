#!/usr/bin/env bash

set -e

APP_CONTAINER_NAME="lanager"

echo "Changing /app/storage owner to UID 1000 and group to GID 1000"
docker run --rm --workdir /app/storage --volumes-from "${APP_CONTAINER_NAME}" busybox chown -R 1000:1000 .

echo "Changing /app/storage permissions to 775"
docker run --rm --workdir /app/storage --volumes-from "${APP_CONTAINER_NAME}" busybox chmod -R 775 .

echo "Done"
