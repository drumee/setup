#!/bin/sh
#set -e

# Source debconf library
. /usr/share/debconf/confmodule

echo "Installing Drumee from Debian Packages"
script_dir=$(dirname $(readlink -f $0))

. ${script_dir}/functions

db_input high drumee/reinstall || true
db_go
db_get drumee/reinstall
if [ $RET = "quit" ]; then
  exit 0
fi

db_input high drumee/description || true

# DRUMEE_DOMAIN_NAME
dom_pattern="^([a-zA-Z0-9_\-]+)(\.[a-zA-Z0-9_\-]+)*$"
db_input high drumee/domain || true
db_go
db_get drumee/domain 
is_valid=$(echo $RET | grep -E "$dom_pattern")
while [ "$is_valid" = "" ]
do
  db_input high drumee/domain || true
  db_go
  db_get drumee/domain
  is_valid=$(echo $RET | grep -E "$dom_pattern")
done
export DRUMEE_DOMAIN_NAME=$RET

if [ "$DRUMEE_DOMAIN_NAME" = "local" ]; then
  db_input high drumee/local_mode || true
  db_go
  db_get drumee/local_mode
  LOCAL_MODE=$RET
else
  db_input high drumee/services || true
  db_go
  db_get drumee/services
  SERVICES=$RET
fi

# PUBLIC_IP4
ip4_pattern="^([0-9]{1,3})(\.[0-9]{1,3}){3}$"
db_input high drumee/public_ip4 || true
db_go
db_get drumee/public_ip4
is_valid=$(echo $RET | grep -E "$ip4_pattern")
while [ "$is_valid" = "" ]
do
  db_input high drumee/public_ip4 || true
  db_go
  db_get drumee/public_ip4
  is_valid=$(echo $RET | grep -E "$ip4_pattern")
done
export PUBLIC_IP4=$RET

# PUBLIC_IP6
ip6_pattern="^([[:xdigit:]]{1,4})(:[[:xdigit:]]{0,4})*$"
db_input high drumee/public_ip6 || true
db_go
db_get drumee/public_ip6 
is_valid=$(echo $RET | grep -E "$ip6_pattern")
while [ "$is_valid" = "" ]
do
  db_input high drumee/public_ip6 || true
  db_go
  db_get drumee/public_ip6
  is_valid=$(echo $RET | grep -E "$ip6_pattern")
done
export PUBLIC_IP6=$RET

# ADMIN_EMAIL
email_pattern="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$"
db_input high drumee/admin_email || true
db_go
db_get drumee/admin_email 
is_valid=$(echo $RET | grep -E "$email_pattern")
while [ "$is_valid" = "" ]
do
  db_input high drumee/admin_email || true
  db_go
  db_get drumee/admin_email
  is_valid=$(echo $RET | grep -E "$email_pattern")
done
export ADMIN_EMAIL=$RET

# ACME_EMAIL_ACCOUNT
db_input high drumee/acme_email_account || true
db_go
db_get drumee/acme_email_account
if [ "$RET" = "" ]; then
  export ACME_EMAIL_ACCOUNT=$ADMIN_EMAIL
else 
  is_valid=$(echo $RET | grep -E "$email_pattern")
  while [ "$is_valid" = "" ]
  do
  db_input high drumee/acme_email_account || true
  db_go
  db_get drumee/acme_email_account
    is_valid=$(echo $RET | grep -E "$email_pattern")
  done
  export ACME_EMAIL_ACCOUNT=$RET
fi

# DRUMEE_DB_DIR
dir_pattern='^/+(usr|bin|sys|proc|tmp|etc|lib.*|boot|dev|sbin|opt|media|mnt|vmlinuz.*|lost.+|snap|root|run|initrd.*)'
db_input high drumee/db_dir || true
db_go
db_get drumee/db_dir
is_valid=$(echo $RET | grep -E "$dir_pattern")
while [ "$is_valid" != "" ]
do
  db_input high drumee/db_dir || true
  db_go
  db_get drumee/db_dir
  is_valid=$(echo $RET | grep -E "$dir_pattern")
done
export DRUMEE_DB_DIR=$RET

# DRUMEE_DATA_DIR
db_input high drumee/data_dir || true
db_go
db_get drumee/data_dir
is_valid=$(echo $RET | grep -E "$dir_pattern")
while [ "$is_valid" != "" ]
do
  db_input high drumee/data_dir || true
  db_go
  db_get drumee/data_dir
  is_valid=$(echo $RET | grep -E "$dir_pattern")
done
export DRUMEE_DATA_DIR=$RET

# BACKUP_LOCATION
db_input high drumee/backup_location || true
db_go
db_get drumee/backup_location

export BACKUP_LOCATION=$RET

db_stop