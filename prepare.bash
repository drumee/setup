#!/bin/bash
script_dir=$(dirname $(readlink -f $0))
base_dir=$(dirname $script_dir)
source $script_dir/utils/dependencies

ensure_node_packages
ensure_postfix
ensure_jitsi $base_dir/preset/jitsi
ensure_mariadb
