#!/bin/bash


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
function setup_prosody() {
  echo Configuring prosody creadentials

  # Ensure prosody start before using prosodyctl
  service prosody restart
  host="auth.${JITSI_DOMAIN}"
  #jic_pw=$(grep password /etc/jitsi/jicofo/jicofo.conf | awk '{print $3}' | sed -e s/\"//g)
  #jvb_pw=$(grep PASSWORD /etc/jitsi/videobridge/jvb.conf | awk '{print $3}' | sed -e s/\"//g)
  addUser focus $JICOFO_PASSWORD $host
  addUser jvb $JVB_PASSWORD $host
  addUser $APP_ID $APP_PASSWORD $JITSI_DOMAIN

  pub_ip=$(grep public-address /etc/jitsi/videobridge/jvb.conf | awk '{print $3}' | sed -e s/\"//g)
  if [ "$pub_ip" != "" ]; then
    o=$(grep ${pub_ip} /etc/hosts)
    if [ "$o" == "" ]; then
      echo "${pub_ip} ${JITSI_DOMAIN}" >>/etc/hosts
    fi
  fi
  echo Subscribing roster command for focus."${JITSI_DOMAIN}" focus@${host}
  prosodyctl mod_roster_command subscribe focus."${JITSI_DOMAIN}" focus@${host}
  #echo prosodyctl mod_roster_command subscribe focus."${JITSI_DOMAIN}" focus@${host}
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
}

#-------------------
function restart_prosody() {
  if [ -f /var/run/prosody/prosody.pid ]; then
    set +e
    ppid=$(cat /var/run/prosody/prosody.pid)
    echo "Prosody PID =$ppid"
  fi
}

#-------------------
function write_version() {
  echo Creating versions file
  mkdir -p /etc/jitsi
  dest=/etc/jitsi/versions.js
  echo "module.exports={" >$dest
  dpkg -l | egrep "ii +jitsi" | awk '{print  "\"", $2, "\"", ":", "\"", $3, "\"", ","}' | sed -E "s/ +//g" >>$dest
  echo "}" >>$dest
  echo Versions file created
}

#-------------------
function install_jitsi() {
  # Jitsi package
  echo Checking jitsi-meet packages
  installed=$(dpkg -l | egrep "^ii +jitsi-meet ")
  if [ "$installed" = "" ]; then
    key=/etc/apt/trusted.gpg.d/jitsi-key.gpg
    if [ ! -f $key ]; then
      curl -sS https://download.jitsi.org/jitsi-key.gpg.key | gpg --dearmor | tee j$key >/dev/null 2>&1
    fi

    source=/etc/apt/sources.list.d/jitsi-stable.list
    if [ ! -f $jitsi_source ]; then
      echo "deb https://download.jitsi.org stable/" | tee $source
      apt update
    fi
    DEBIAN_FRONTEND="noninteractive" apt install -y jitsi-meet
  else
    echo "Jitsi package alreay installed. Skipped."
  fi
}
