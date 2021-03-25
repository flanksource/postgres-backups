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

set -x
initialize_restic_repo
dump | restic_backup
[[ ${PIPESTATUS[0]} != 0 || ${PIPESTATUS[1]} != 0 ]] && (( ERRORCOUNT += 1 ))
set +x

exit "$ERRORCOUNT"
