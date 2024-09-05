#!/bin/bash
set -e
script_dir=$(dirname $(readlink -f $0))
base_dir=$(dirname $script_dir)
cd $script_dir

echo "Confuring Drumee Schemas"
source /etc/drumee/drumee.sh
mkdir -p /tmp/drumee
chown -R $DRUMEE_SYSTEM_USER:$DRUMEE_SYSTEM_GROUP /tmp/drumee/

service mariadb stop
if [ "$DRUMEE_DB_DIR" = "" ];then
  DRUMEE_DB_DIR=/srv/db
fi

run_dir=${DRUMEE_DB_DIR}/run
if [ -d "$run_dir" ]; then
  orig=${DRUMEE_DB_DIR}/orig/$(date +%Y-%m-%d)
  mkdir -p ${DRUMEE_DB_DIR}/orig
  mv $run_dir $orig
fi

mkdir -p $run_dir
mkdir -p /var/log/drumee/ 

log=/var/log/drumee/seeds.log
date > $log

SEEDS_FILE=/var/drumee/setup/data/seeds.tgz
echo Extracting schemas seeds
tar -xf $SEEDS_FILE --checkpoint=.50 --one-top-level=seeds
echo
echo Copying schemas seeds
mariabackup --copy-back --target-dir=$script_dir/seeds >> ${log} 2>>${log}

echo Preparing db data dir
chown -R mysql:mysql $run_dir
chmod -R go-rwx $run_dir
service mariadb start

mariadb -e "CREATE OR REPLACE USER '$DRUMEE_SYSTEM_USER'@'localhost' IDENTIFIED VIA unix_socket"
mariadb -e "GRANT ALL PRIVILEGES ON *.* TO '$DRUMEE_SYSTEM_USER'@'localhost'"
cd $base_dir
node schemas/index.js
chown -R $DRUMEE_SYSTEM_USER:$DRUMEE_SYSTEM_GROUP $DRUMEE_ROOT
chown -R $DRUMEE_SYSTEM_USER:$DRUMEE_SYSTEM_GROUP $DRUMEE_DATA_DIR
echo "Drumee Schemas completed!"

