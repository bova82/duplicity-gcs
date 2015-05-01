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

#base command
BASE_BKP_CMD="duplicity"

#Checking source and destination
if [ -z "$SRC" -o -z "$DEST" ]; then
  if [ -z "$SRC" ]; then
    echo "Source must be specified"
  fi
  if [ -z "$DEST" ]; then
    echo "Destination must be specified"
  fi
  exit 1
fi

#Encryption and signing
if [ ! -z "$GPG_SIGN_KEY" ]; then
	  BASE_BKP_CMD="${BASE_BKP_CMD} --sign-key ${GPG_SIGN_KEY}"
fi
if [ ! -z "$GPG_ENCR_KEY" ]; then
  BASE_BKP_CMD="${BASE_BKP_CMD} --encrypt-key ${GPG_ENCR_KEY}"
else
  BASE_BKP_CMD="${BASE_BKP_CMD} --no-encryption"
fi

#Setting log file
LOGGABLE=false
if [ ! -z "$FULL_BACKUP_EVERY" ]; then
  BKP_CMD="${BASE_BKP_CMD} --full-if-older-than ${FULL_BACKUP_EVERY}"
fi
LOG_CMD=""
LOG_APPEND_CMD=""
if [ ! -z "$LOG_DIR" ]; then
  cd $LOG_DIR
  NOW="$(date +'%Y%m%d%H%M%S')"
  LOG_FILE="duplicity${NOW}.log"

  #testing if file is writeable
  touch $LOG_FILE
  if [ -w "$LOG_FILE" ]; then
  	LOGGABLE=true
  	#echo "Log file is writable"
  	rm $LOG_FILE
  else
  	echo "Log file is not writable. Change or remove logging directory. Exiting."
  	exit 1
  fi

fi

# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} [-hl] ...
    -h			display this help and exit
    -l			list backups
EOF
}

execute_backup() {
	#echo "${BKP_CMD} ${SRC} ${DEST}"
	echo "### Backup script start ###"
	echo "Backup in progress from ${SRC} to ${DEST}"
	eval "${BKP_CMD} ${SRC} ${DEST}"

	if [ ! -z "$FULL_BACKUPS_TO_MANTAIN" ]; then
	  echo "Cleaning old full backups in ${DEST}"
	  BKP_CLEAN_CMD="${BASE_BKP_CMD} remove-all-but-n-full ${FULL_BACKUPS_TO_MANTAIN} --force ${DEST}"
	  #echo "${BKP_CLEAN_CMD}"
	  eval "${BKP_CLEAN_CMD}"
	fi
	echo "### Backup script end ###"
}


if [ $# -eq 0 ];
then
#no options passed
	if [ $LOGGABLE ]; then
    	execute_backup &> $LOG_FILE
	else
		execute_backup
	fi
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
				BKP_LIST_CMD="${BASE_BKP_CMD} collection-status ${DEST}"
				if [ $LOGGABLE ]; then
			    	eval $BKP_LIST_CMD &> $LOG_FILE
				else
					eval $BKP_LIST_CMD
				fi
				eval  
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
