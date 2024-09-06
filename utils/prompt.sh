

# 
prompt () {
  name=$1
  pattern=$2
  toggle=$3
  db_input high $name || true
  db_get $name  
  is_valid=$(echo $RET | grep -E "$pattern")
  if ["$toggle" = "" ]; then
    while [ "$is_valid" = "" ]
    do
      db_input high $name || true
      db_get $name
      is_valid=$(echo $RET | grep -E "$pattern")
    done 
  else 
    while [ "$is_valid" != "" ]
    do
      db_input high $name || true
      db_get $name
      is_valid=$(echo $RET | grep -E "$pattern")
    done 
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
    yp=$(mysql yp -e "select main_domain() mydomain")
    if [ "$yp" = "" ]; then
      RET=maiden
    else
      RET=exists
    fi
  fi
}
