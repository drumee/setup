#!/bin/bash

source /etc/drumee/drumee.sh
source /etc/prosody/defaults/credentials.sh

set +e
#-------------------
function setup_dirs() {
  echo Configuring directories permissions

  ca_dir=/usr/local/share/ca-certificates
  mkdir -p $ca_dir

  cert_file="${ACME_CERTS_DIR}/${JITSI_DOMAIN}_ecc/${JITSI_DOMAIN}"
  target="${ca_dir}/auth.${JITSI_DOMAIN}"

  if [ -f "${cert_file}.cer" ]; then
    ln -sf "${cert_file}.cer" "${target}.cer"
  fi

  if [ -f "${cert_file}.key" ]; then
    chmod g+r "${cert_file}.key"
    ln -sf "${cert_file}.key" "${target}.key"
  fi

  mkdir -p $DRUMEE_RUNTIME_DIR/prosody
  chown -R prosody:prosody $DRUMEE_RUNTIME_DIR/prosody

  auth=$(echo auth.${JITSI_DOMAIN} | sed -e "s/\./\%2e/g" | sed -e "s/\-/\%2d/g" | sed -e "s/\_/\%5f/g")
  mkdir -p "/etc/drumee/credential/prosody/data/${auth}"
  chown -R prosody:prosody /etc/drumee/credential/prosody
}

#-------------------
function addUser() {
  user=$1
  secret=$2
  host=$3
  # user_exists=$(prosodyctl adduser ${user}@${host} < /dev/null || true)
  # if [ "$user_exists" = "That user already exists" ]; then
  # fi
  prosodyctl deluser ${user}@${host}
  prosodyctl register ${user} ${host} $secret
}

#-------------------
# Sometime service prosody restart is not working
function restart_prosody() {
  if [ -f /var/run/prosody/prosody.pid ]; then
    set +e
    ppid=$(cat /var/run/prosody/prosody.pid)
    echo "Prosody PID =$ppid"
    if [ "$ppid" != "" ]; then
      kill $ppid;
      sleep 3
      service prosody start
    else
      service prosody restart
    fi
  else
    service prosody restart
  fi
}

#-------------------
function setup_prosody() {
  echo Configuring prosody creadentials

  # Ensure prosody start before using prosodyctl
  restart_prosody
  auth_host="auth.${JITSI_DOMAIN}"
  addUser focus $JICOFO_PASSWORD $auth_host
  addUser jvb $JVB_PASSWORD $auth_host
  addUser $APP_ID $APP_PASSWORD $JITSI_DOMAIN

  pub_ip=$(grep public-address /etc/jitsi/videobridge/jvb.conf | awk '{print $3}' | sed -e s/\"//g)
  if [ "$pub_ip" != "" ]; then
    o=$(grep ${pub_ip} /etc/hosts)
    if [ "$o" == "" ]; then
      echo "${pub_ip} ${JITSI_DOMAIN}" >>/etc/hosts
    fi
  fi
  echo prosodyctl mod_roster_command subscribe "focus.${JITSI_DOMAIN}" "focus@${auth_host}"
  prosodyctl mod_roster_command subscribe "focus.${JITSI_DOMAIN}" "focus@${auth_host}"
  echo Prosody creadentials done
}

#-------------------
function clean_vendor_files() {
  echo Removing native files installed by jitsi-meet package
  rm -f /etc/nginx/sites-enabled/default
  rm -f /etc/prosody/conf.d/jitsi.meet.cfg.lua
  rm -f /etc/jitsi/videobridge/sip-communicator.properties
  rm -f /etc/prosody/conf.avail/example.com.cfg.lua
  rm -f /etc/prosody/conf.avail/jaas.cfg.lua
  rm -f /etc/prosody/conf.avail/jitsi.meet.cfg.lua
  rm -rf /etc/prosody/certs/*
  rm -rf /var/lib/prosody/*jitsi.meet.*
}


