#! /usr/bin/env bash

# enable unofficial bash strict mode
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

PG_BIN=$PG_DIR/$PG_VERSION/bin
ERRORCOUNT=0

function initialize_restic_repo {
  echo "Checking configured repository '${RESTIC_REPOSITORY}' ..."
  if restic cat config > /dev/null; then
    echo "Repository found."
  else
    echo "Could not access the configured repository. Trying to initialize (in case it has not been initialized yet) ..."
    if restic init; then
      echo "Repository successfully initialized."
    else
      if [ "${SKIP_INIT_CHECK:-}" == "true" ]; then
        echo "Initialization failed. Ignoring errors because SKIP_INIT_CHECK is set in your configuration."
      else
        echo "Initialization failed. Please see error messages above and check your configuration. Exiting."
        exit 1
      fi
    fi
  fi
  echo -e "\n"
}

function dump {
    "$PG_BIN"/pg_dumpall --verbose --no-owner --no-acl --no-role-passwords
}

function restic_backup {
    BACKUP_FILENAME=${PGHOST}-$(date "+%Y-%m-%d.%H%M%S").sql
    restic backup --tag "${PGHOST}" --tag "logical-backup" --stdin --stdin-filename "$BACKUP_FILENAME"
}

function delete_old_backups {
  args=()

  [[ -n "${BACKUP_RETENTION_KEEP_LAST:-}" ]] && args+=(--keep-last "$BACKUP_RETENTION_KEEP_LAST")
  [[ -n "${BACKUP_RETENTION_KEEP_HOURLY:-}" ]] && args+=(--keep-hourly "$BACKUP_RETENTION_KEEP_HOURLY")
  [[ -n "${BACKUP_RETENTION_KEEP_DAILY:-}" ]] && args+=(--keep-daily "$BACKUP_RETENTION_KEEP_DAILY")
  [[ -n "${BACKUP_RETENTION_KEEP_WEEKLY:-}" ]] && args+=(--keep-weekly "$BACKUP_RETENTION_KEEP_WEEKLY")
  [[ -n "${BACKUP_RETENTION_KEEP_MONTHLY:-}" ]] && args+=(--keep-monthly "$BACKUP_RETENTION_KEEP_MONTHLY")
  [[ -n "${BACKUP_RETENTION_KEEP_YEARLY:-}" ]] && args+=(--keep-yearly "$BACKUP_RETENTION_KEEP_YEARLY")

  if [[ "${#args[@]}" -gt "0" ]]; then
    echo "Deleting old backups based on retention rule:" "${args[@]//\'/}"
    restic forget --group-by tags --tag "${PGHOST}" "${args[@]//\'/}" --prune
  else
    echo "No retention rules detected. Skip deleting old backup"
  fi
}

set -x
initialize_restic_repo
dump | restic_backup
[[ ${PIPESTATUS[0]} != 0 || ${PIPESTATUS[1]} != 0 ]] && (( ERRORCOUNT += 1 ))
delete_old_backups
set +x

exit "$ERRORCOUNT"
