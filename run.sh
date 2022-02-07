#!/bin/bash

IPV4="203.0.113.0"
IPV6="2001:db8:ffff:ffff:ffff:ffff:ffff:ffff"

while [[ true ]]; do
    sleep 1

    C=$(curl -4 ifconfig.co 2>/dev/null)
    if [[ "$IPV4" != "$C" ]];then
        sed -i "s/$IPV4/$C/g" /opt/AdGuardHome/AdGuardHome.yaml
        killall -9 AdGuardHome >/dev/null 2>&1 &
        killall -9 sniproxy >/dev/null 2>&1 &
        sleep 1
        /opt/AdGuardHome/AdGuardHome --no-check-update -c /opt/AdGuardHome/AdGuardHome.yaml 2>&1 &
        /usr/sbin/sniproxy -c /etc/sniproxy.conf -f 2>&1 &
        IPV4=$C
    fi

    C=$(curl -6 ifconfig.co 2>/dev/null)
    if [[ "$IPV6" != "$C" ]];then
        sed -i "s/$IPV6/$C/g" /opt/AdGuardHome/AdGuardHome.yaml
        killall -9 AdGuardHome >/dev/null 2>&1 &
        killall -9 sniproxy >/dev/null 2>&1 &
        sleep 1
        /opt/AdGuardHome/AdGuardHome --no-check-update -c /opt/AdGuardHome/AdGuardHome.yaml 2>&1 &
        /usr/sbin/sniproxy -c /etc/sniproxy.conf -f 2>&1 &
        IPV6=$C
    fi
done
