#!/bin/sh
set -e
. /usr/share/debconf/confmodule

echo "Installing Drumee Team Meta Package"
script_dir=`dirname $(readlink -f $0)`
. $script_dir/utils/misc.sh
. $script_dir/utils/prompt.sh

check_installation
if [ "$RET" = "maiden" ]; then
  select_installation_mode
  if [ "$RET" = "menu" ]; then
    $script_dir/menu/install.sh
  fi
  $script_dir/prepare.bash
  $script_dir/infra.bash
  $script_dir/schemas.bash
else 
  should_reinstall
  if [ "$RET" = "remove" ]; then
    export FORCE_INSTALL=yes
    service mariadb stop
    echo rm -rf $DRUMEE_DB_DIR
    echo rm -rf $DRUMEE_DATA_DIR
    $script_dir/menu/install.sh
    $script_dir/prepare.bash
    $script_dir/infra.bash
    $script_dir/schemas.bash
  else
    echo updating
  fi
done
