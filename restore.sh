#! /usr/bin/env bash

# enable unofficial bash strict mode
set -o errexit
set -o nounset
set -o pipefail
set -x
IFS=$'\n\t'

PG_BIN=$PG_DIR/$PG_VERSION/bin

if [[ -z "$BACKUP_PATH" ]]; then
  echo "Missing path to backup file. Please set it via \$BACKUP_PATH"
  exit 1
fi

snapshot_info_json=$(restic snapshots --path "$BACKUP_PATH" --json)

if [[ "$(echo "$snapshot_info_json" | jq -r 'length')" -lt "1" ]]; then
  echo "Could not find the backup file at $BACKUP_PATH"
  exit 2
fi

echo "Restoring..."
restic dump --path "$BACKUP_PATH" latest "$BACKUP_PATH" | psql -d "$PGDATABASE" "$PSQL_OPTS"
echo "Done."
