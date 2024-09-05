#!/bin/sh
set -e

. /usr/share/debconf/confmodule
script_dir=$(dirname $(readlink -f $0))

. ${script_dir}/utils/prompt.sh

db_input high drumee/reinstall || true
db_go
db_get drumee/reinstall

export MENU_RET=$RET

db_stop