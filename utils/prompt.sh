
if [ -x /usr/bin/mysql ]; then
  DB_CLI=/usr/bin/mysql
elif [ -x /usr/bin/mariadb ]; then
  DB_CLI=/usr/bin/mariadb
fi
debug=/var/tmp/drumee/debug.log

#
log() {
  local message="$1"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "${timestamp}: ${message}" >> $debug
}

#
read_response () {
  db_input high $1 || true
  db_go
  db_get $1
}

# 
handle_trap () {
  echo trapped
}

# name of the input
# pattern validity check of the ipnupt value
# toggle set validity is checked again negative pattern
prompt () {
  local name=$1
  local pattern=$2
  local toggle=$3
  local is_valid=
  read_response $name
  if [ "$pattern" != "" ]; then
    is_valid=$(echo $RET | egrep -io "$pattern")
    if [ "$toggle" = "" ]; then
      while [ "$is_valid" = "" ]
      do
        read_response $name
        is_valid=$(echo $RET | egrep -io "$pattern")
        sleep 1
      done 
    else 
      while [ "$is_valid" != "" ]
      do
        read_response $name
        is_valid=$(echo $RET | egrep -io "$pattern")
        sleep 1
      done 
    fi
  fi
}

should_reinstall () {
  db_input high drumee/reinstall || true
  db_go
  db_get drumee/reinstall
  if [ "$RET" = "quit" ]; then
    exit 0
  fi
}


#
select_installation_mode () {
  RET=auto
  for i in DRUMEE_DOMAIN_NAME PUBLIC_IP4 PUBLIC_IP6 ADMIN_EMAIL DRUMEE_DB_DIR DRUMEE_DATA_DIR; do
    e=`eval echo '$'$i`
    if [ "$e" = "" ]; then
      RET=menu
      break
    fi
  done
}

#
check_installation () {
  RET=maiden
  if [ -f /etc/drumee/drumee.sh ]; then
    . /etc/drumee/drumee.sh
    yp=$($DB_CLI yp -e "select main_domain() mydomain")
    if [ "$yp" = "" ]; then
      RET=maiden
    else
      RET=exists
    fi
  fi
}

preset_ip_addr () {
  V4=""
  V6=""
  for i in $(ifconfig -a | grep inet | awk '{print $2}'); do
    isv4=$(echo $i | egrep -io "^([0-9]{1,3})(\.[0-9]{1,3}){3}$")
    isv6=$(echo $i | egrep -io "([a-f0-9:]+:+)+[a-f0-9]+")
    if [ "$isv4" != "" ]; then
      if [ "$V4" = "" ]; then
        V4=$i
      else
        V4="$i, $V4"
      fi
    elif [ "$isv6" != "" ]; then
      if [ "$V6" = "" ]; then
        V6=$i
      else
        V6="$i, $V6"
      fi
    fi
  done
  db_subst drumee-infra/ip4 __IP4_LIST__ "$V4"
  db_subst drumee-infra/ip6 __IP6_LIST__ "$V6"
  db_go
} 