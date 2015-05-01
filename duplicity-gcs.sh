#!/bin/sh
#SOURCE AND DESTINATION
SRC=dir
#gs://<storage> or gs://<storage>/path/to/folder
DEST=gs://storage

#BACKUP SETTINGS
FULL_BACKUPS_TO_MANTAIN=2
FULL_BACKUP_EVERY=1M
#GOOGLE CLOUD STORAGE SETTINGS
GOOGLE_STORAGE_KEY="key"
GOOGLE_STORAGE_SECRET="secret"
#ENCRYPTION AND SIGNING SETTINGS
GPG_ENCR_KEY=ENCR_KEY
GPG_SIGN_KEY=SIGN_KEY
#Encryption passphrases. They must have to be set to avoid prompt password request
GPG_ENCR_PASSPHRASE="encryption_password"
GPG_SIGN_PASSPHRASE="signing_password"
#LOGGING
#File are created inside the specified directory (check if you have the permissions)
#The file name is duplicity<YYYYMMDDhhmmss>.log with the current timestamp
#If not specified non log file is written
LOG_DIR="/tmp"

#Exporting environment variables
if [ -z "$GOOGLE_STORAGE_KEY" ]; then
  export GS_ACCESS_KEY_ID=$GOOGLE_STORAGE_KEY
fi
if [ -z "$GOOGLE_STORAGE_SECRET" ]; then
  export GS_ACCESS_KEY_ID=$GOOGLE_STORAGE_SECRET
fi

if [ -z "$GPG_ENCR_PASSPHRASE" ]; then
  export PASSPHRASE=$GPG_ENCR_PASSPHRASE
fi
if [ -z "$GPG_SIGN_PASSPHRASE" ]; then
  export SIGN_PASSPHRASE=$GPG_SIGN_PASSPHRASE
fi

# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} [-hl] ...
    -h			display this help and exit
    -l			list backups
EOF
}

if [ -z "$SRC" -o -z "$DEST" ]; then
  if [ -z "$SRC" ]; then
    echo "Source must be specified"
  fi
  if [ -z "$DEST" ]; then
    echo "Destination must be specified"
  fi
  exit 1
fi
BASE_BKP_CMD="duplicity"
if [ ! -z "$GPG_SIGN_KEY" ]; then
	  BASE_BKP_CMD="${BASE_BKP_CMD} --sign-key ${GPG_SIGN_KEY}"
fi
if [ ! -z "$GPG_ENCR_KEY" ]; then
  BASE_BKP_CMD="${BASE_BKP_CMD} --encrypt-key ${GPG_ENCR_KEY}"
else
  BASE_BKP_CMD="${BASE_BKP_CMD} --no-encryption"
fi

execute_backup() {
	if [ ! -z "$FULL_BACKUP_EVERY" ]; then
	  BKP_CMD="${BASE_BKP_CMD} --full-if-older-than ${FULL_BACKUP_EVERY}"
	fi
	LOG_CMD=""
	LOG_APPEND_CMD=""
	if [ ! -z "$LOG_DIR" ]; then
	  cd $LOG_DIR
	  NOW="$(date +'%Y%m%d%H%M%S')"
	  LOG_FILE="duplicity${NOW}.log"
	  LOG_CMD="&> ${LOG_FILE}"
	  LOG_APPEND_CMD="&>> ${LOG_FILE}"
	fi
	pwd
	echo "${BKP_CMD} ${SRC} ${DEST} ${LOG_CMD}"
	eval "${BKP_CMD} ${SRC} ${DEST} ${LOG_CMD}"

	if [ ! -z "$FULL_BACKUPS_TO_MANTAIN" ]; then
	  BKP_CLEAN_CMD="${BASE_BKP_CMD} remove-all-but-n-full ${FULL_BACKUPS_TO_MANTAIN} --force ${DEST}"
	  echo "${BKP_CLEAN_CMD} ${LOG_CMD}"
	  eval "${BKP_CLEAN_CMD} ${LOG_CMD}"
	fi
}


if [ $# -eq 0 ];
then
#no options passed
    execute_backup
    exit 0
else
#some options passed
	OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
	while getopts "hlc:" opt; do
	    case "$opt" in
	        h)
	            show_help
	            exit 0
	            ;;
	        #TODO generare stringa in funzione
	        l)
				eval  "${BASE_BKP_CMD} collection-status ${DEST}"
	            ;;
	        '?')
	            show_help
	            exit 0
	            ;;
	    esac
	done
	shift "$((OPTIND-1))" # Shift off the options and optional --.
	 
	#printf '<%s>\n' "$@"
fi