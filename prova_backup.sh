#!/bin/sh

#SOURCE AND DESTINATION
SRC=/dir
#gs://<storage> or gs://<storage>/path/to/folder
DEST=gs://<storage>

#BACKUP SETTINGS
FULL_BACKUPS_TO_MANTAIN=2
FULL_BACKUP_EVERY=1M


#GOOGLE CLOUD STORAGE SETTINGS
GOOGLE_STORAGE_KEY="key"
GOOGLE_STORAGE_SECRET="secret"

#ENCRYPTION AND SIGNING SETTINGS
GPG_ENCR_KEY=ENCR_KEY
GPG_SIGN_KEY=SIGN_KEY
GPG_ENCR_PASSPHRASE="encryption_password"
GPG_SIGN_PASSPHRASE="signing_password"

#Exporting environment variables
export GS_ACCESS_KEY_ID=$GOOGLE_STORAGE_KEY
export GS_SECRET_ACCESS_KEY=$GOOGLE_STORAGE_SECRET
export PASSPHRASE=$GPG_ENCR_PASSPHRASE
export SIGN_PASSPHRASE=$GPG_SIGN_PASSPHRASE

# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} [-hl] [-c CONFIG] ...
    -h			display this help and exit
    -l			list backups
    -c CONFIG 		read configuration from CONFIG_FILE
EOF
}

# Initialize our own variables:
config_file=""

OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts "hlc:" opt; do
    case "$opt" in
        h)
            show_help
            exit 0
            ;;
        l)  duplicity --sign-key ${GPG_SIGN_KEY} --encrypt-key ${GPG_ENCR_KEY} collection-status ${DEST}
            ;;
        c)  config_file=$OPTARG
            ;;
        '?')
            duplicity --sign-key ${GPG_SIGN_KEY} --encrypt-key ${GPG_ENCR_KEY} --full-if-older-than ${FULL_BACKUP_EVERY} ${SRC} ${DEST}
			duplicity --sign-key ${GPG_SIGN_KEY} --encrypt-key ${GPG_ENCR_KEY} remove-all-but-n-full ${FULL_BACKUPS_TO_MANTAIN} --force ${DEST}
			duplicity --sign-key ${GPG_SIGN_KEY} --encrypt-key ${GPG_ENCR_KEY} collection-status ${DEST}
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))" # Shift off the options and optional --.
 
printf '<%s>\n' "$@"
