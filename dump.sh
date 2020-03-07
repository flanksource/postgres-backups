#! /usr/bin/env bash

# enable unofficial bash strict mode
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

ALL_DB_SIZE_QUERY="select sum(pg_database_size(datname)::numeric) from pg_database;"
PG_BIN=$PG_DIR/$PG_VERSION/bin
DUMP_SIZE_COEFF=5
ERRORCOUNT=0

function estimate_size {
    "$PG_BIN"/psql -tqAc "${ALL_DB_SIZE_QUERY}"
}

function dump {
    "$PG_BIN"/pg_dumpall --verbose --no-owner --no-acl --no-role-passwords --if-exists
}

function compress {
    pigz
}

function aws_upload {
    declare -r EXPECTED_SIZE="$1"
    PATH_TO_BACKUP=s3://$LOGICAL_BACKUP_S3_BUCKET/${PGHOST}/$(date "+%Y-%m-%d.%H%M%S").sql.gz

    args=()

    [[ ! -z "$EXPECTED_SIZE" ]] && args+=("--expected-size=$EXPECTED_SIZE")
    [[ ! -z "$LOGICAL_BACKUP_S3_ENDPOINT" ]] && args+=("--endpoint-url=$LOGICAL_BACKUP_S3_ENDPOINT")
    [[ ! -z "$LOGICAL_BACKUP_S3_REGION" ]] && args+=("--region=$LOGICAL_BACKUP_S3_REGION")
    [[ ! -z "$LOGICAL_BACKUP_S3_SSE" ]] && args+=("--sse=$LOGICAL_BACKUP_S3_SSE")

    aws s3 cp - "$PATH_TO_BACKUP" "${args[@]//\'/}"
}


set -x
dump | compress | aws_upload $(($(estimate_size) / DUMP_SIZE_COEFF))
[[ ${PIPESTATUS[0]} != 0 || ${PIPESTATUS[1]} != 0 || ${PIPESTATUS[2]} != 0 ]] && (( ERRORCOUNT += 1 ))
set +x

exit $ERRORCOUNT
