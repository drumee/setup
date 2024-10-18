#!/bin/sh
set -e
. /usr/share/debconf/confmodule

echo "Installing Drumee Team Meta Package"
script_dir=`dirname $(readlink -f $0)`
. $script_dir/utils/prompt.sh

do_install () {
  select_installation_mode
  if [ "$RET" = "menu" ]; then
    $script_dir/menu/install.sh
  fi
  # env.sh may be updated by install or another automation
  if [ -f  /var/tmp/drumee/env.sh ]; then
    . /var/tmp/drumee/env.sh
    echo 17:DRUMEE_DOMAIN_NAME=$DRUMEE_DOMAIN_NAME
    $script_dir/infra/bin/install
    $script_dir/schemas/bin/install
  else
    echo failed to configure
    exit 1
  fi
  exit 0
}

check_installation
if [ "$RET" = "maiden" ]; then
  do_install
else 
  should_reinstall
  if [ "$RET" = "remove" ]; then
    export FORCE_INSTALL=yes
    service mariadb stop
    echo rm -rf $DRUMEE_DB_DIR
    echo rm -rf $DRUMEE_DATA_DIR
    do_install
  else
    echo run dpkg-reconigure drumee-infra
  fi
fi
