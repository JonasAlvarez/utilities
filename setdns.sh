#!/bin/bash

logdest="user.notice"

HOSTNAME="<HOSTNAME>"
USERNAME="<USERNAME>"
PASSWORD="<PASSWPORD>"

myip=`curl -s "https://domains.google.com/checkip"`
dnsip=`dig +short $HOSTNAME | grep '^[.0-9]*$'`

logger -p $logdest "google_dns: external IP is $myip, Google DNS IP is $dnsip"

if [ "$dnsip" != "$myip" -a "$myip" != "" ]; then
  echo "IP has changed!! Updating on Google"
  m=$(curl -s "https://${USERNAME}:${PASSWORD}@domains.google.com/nic/update?hostname=${HOSTNAME}&myip=${myip}")

  if [ $? -ne 0 ]
  then
    logger -p $logdest "google_dns: Error ${m} changing IP on ${hostname}.${HOSTNAME} from ${dnsip} to ${myip}"
  else
    logger -p $logdest "google_dns: Changed IP on ${HOSTNAME} from ${dnsip} to ${myip}"
  fi
fi
