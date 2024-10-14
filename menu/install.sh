#!/bin/sh
set +e
echo "Installing Drumee from Debian Packages"
script_dir=$(dirname $(readlink -f $0))
base=$(dirname $script_dir)

mkdir -p /var/tmp/drumee
env_file=/var/tmp/drumee/env.sh
echo "# env file automatically generated " > $env_file

# Source debconf library
. /usr/share/debconf/confmodule
. $base/utils/prompt.sh

prompt drumee-test/description
echo export DRUMEE_DESCRIPTION=$RET >> $env_file

prompt drumee-test/domain "^([a-zA-Z0-9_\-]+)(\.[a-zA-Z0-9_\-]+)*$"
echo export DRUMEE_DOMAIN_NAME=$RET >> $env_file

echo cat $env_file

db_stop