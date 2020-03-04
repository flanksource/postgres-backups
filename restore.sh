#! /usr/bin/env bash

# enable unofficial bash strict mode
set -o errexit
set -o nounset
set -o pipefail
set -x
IFS=$'\n\t'

PG_BIN=$PG_DIR/$PG_VERSION/bin

args=()

[[ ! -z "$LOGICAL_BACKUP_S3_ENDPOINT" ]] && args+=("--endpoint-url=$LOGICAL_BACKUP_S3_ENDPOINT")
[[ ! -z "$LOGICAL_BACKUP_S3_REGION" ]] && args+=("--region=$LOGICAL_BACKUP_S3_REGION")
[[ ! -z "$LOGICAL_BACKUP_S3_SSE" ]] && args+=("--sse=$LOGICAL_BACKUP_S3_SSE")

aws s3 cp "$PATH_TO_BACKUP" - "${args[@]//\'/}" | gzip -d > db.sql
$PSQL_BEFORE_HOOK
psql -d $PGDATABASE $PSQL_OPTS < db.sql
$PSQL_AFTER_HOOK
