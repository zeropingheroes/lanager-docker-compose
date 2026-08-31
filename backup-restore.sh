#!/usr/bin/env bash

set -e

APP_CONTAINER_NAME="lanager"
DB_CONTAINER_NAME="db"
STORAGE_VOLUME_NAME="lanager_laravel-storage"
NETWORK_NAME="lanager-docker-compose_lanager-network"

TEMP_DIR="/tmp"
STORAGE_BACKUP_FILENAME="lanager-storage.tar"
DB_BACKUP_FILENAME="lanager-database.sql"
ENV_BACKUP_FILENAME="lanager-environment.env"
LOCAL_ENV_FILENAME=".env"

FORCE=0
SKIP_ENV_FILE=0
FILES=()

usage() {
    echo "Usage: ./backup-restore.sh [--force] [--skip-env-file] <file>"
    echo ""
    echo "Restore a LANager backup file"
    echo ""
    echo "  --force           Skip the overwrite confirmation prompt"
    echo "  --skip-env-file   Don't restore the .env file from the backup"
    echo "  --help            Show this message"
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --force)
            FORCE=1
            shift
            ;;
        --skip-env-file)
            SKIP_ENV_FILE=1
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        --*)
            echo "Error: Unrecognized option: $1"
            echo ""
            usage
            exit 1
            ;;
        *)
            FILES+=("$1")
            shift
            ;;
    esac
done

if [ "${#FILES[@]}" -ne 1 ]; then
    usage
    exit 1
fi

BACKUP_FILE="${FILES[0]}"
BACKUP_FOLDER="$TEMP_DIR/${BACKUP_FILE%.tar.gz}"

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Error: File not found: $BACKUP_FILE"
    exit 1
fi

if [ "$FORCE" -ne 1 ]; then
    echo "WARNING: This will overwrite any local LANager data"

    read -p "Do you wish to continue? " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit
    fi
fi

if [ "$( docker container inspect -f '{{.State.Status}}' $APP_CONTAINER_NAME )" != "running" ]; then
    echo "Error: Container \"$APP_CONTAINER_NAME\" is not running"
    exit 1;
fi

if [ "$( docker container inspect -f '{{.State.Status}}' $DB_CONTAINER_NAME )" != "running" ]; then
    echo "Error: Container \"$DB_CONTAINER_NAME\" is not running"
    exit 1;
fi

echo "Extracting backup file into $BACKUP_FOLDER"
tar xzf "$BACKUP_FILE" -C "$TEMP_DIR"

if [ "$SKIP_ENV_FILE" -ne 1 ]; then
    read -p "Would you like to restore the environment settings (.env) file? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv "$BACKUP_FOLDER/$ENV_BACKUP_FILENAME" ".env"
    fi
fi

echo "Loading database credentials from the .env file into environment variables"
source "$LOCAL_ENV_FILENAME"

echo "Restoring database data from $DB_BACKUP_FILENAME"
docker run -i -e "MYSQL_PWD=$DB_ROOT_PASSWORD" --network $NETWORK_NAME --rm mysql:8 \
   mysql -hDB -uroot lanager < "$BACKUP_FOLDER/$DB_BACKUP_FILENAME"

echo "Destroying all data in the $STORAGE_VOLUME_NAME volume"
docker run --rm --volumes-from $APP_CONTAINER_NAME -v "$BACKUP_FOLDER":/restore zeropingheroes/lanager:develop rm -rf /app/storage/*

echo "Restoring files from the storage directory into the $STORAGE_VOLUME_NAME volume"
docker run --rm --volumes-from $APP_CONTAINER_NAME -v "$BACKUP_FOLDER":/restore zeropingheroes/lanager:develop tar xf "/restore/$STORAGE_BACKUP_FILENAME" \
   -C /

echo "Removing temporary directory"
rm -rf "${BACKUP_FOLDER:?}"

echo "Successfully restored backup archive"
