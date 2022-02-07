#!/bin/bash

IPV4="203.0.113.0"
IPV6="2001:db8:ffff:ffff:ffff:ffff:ffff:ffff"

ping -c 4 1.1.1.1 >/dev/null 2>&1
if [ $? -eq 1 ];then
    sed -i "s/$IPV4/A/g" /opt/AdGuardHome/AdGuardHome.yaml
    IPV4="A"
fi

ping -c 4 2001:4860:4860::8888 >/dev/null 2>&1
if [ $? -eq 1 ];then
    sed -i "s/$IPV6/AAAA/g" /opt/AdGuardHome/AdGuardHome.yaml
    sed -i "s/ipv6_first/ipv4_first/g" /etc/sniproxy.conf
    IPV6="AAAA"
fi

# 造一个错误命令来进入循环
curl 333.333.333.333 2>/dev/null
while [ $? -ne 0 ] 
do
    PASSHASH=$(htpasswd -bnBC 10 "" $PASSWORD | tr -d ':\n' | sed 's/$2y/$2a/')
    sed -i "s/\$2a\$10\$UL51kOUMX6uwmI1y8ddCje.5IQ0.FM4aeTbjC5n3N8Vu9QFZnX.Qq/${PASSHASH}/g" /opt/AdGuardHome/AdGuardHome.yaml >/dev/null 2>&1
done

while [[ true ]]; do
    sleep 1

    C=$(curl -4 ifconfig.co 2>/dev/null)
    if [ $? -eq 0 ];then
        if [[ "$IPV4" != "$C" ]];then
            sed -i "s/$IPV4/$C/g" /opt/AdGuardHome/AdGuardHome.yaml
            killall -9 AdGuardHome >/dev/null 2>&1 &
            killall -9 sniproxy >/dev/null 2>&1 &
            sleep 1
            /opt/AdGuardHome/AdGuardHome --no-check-update -c /opt/AdGuardHome/AdGuardHome.yaml 2>&1 &
            /usr/sbin/sniproxy -c /etc/sniproxy.conf -f 2>&1 &
            IPV4=$C
        fi
    fi

    C=$(curl -6 ifconfig.co 2>/dev/null)
    if [ $? -eq 0 ];then
        if [[ "$IPV6" != "$C" ]];then
            sed -i "s/$IPV6/$C/g" /opt/AdGuardHome/AdGuardHome.yaml
            killall -9 AdGuardHome >/dev/null 2>&1 &
            killall -9 sniproxy >/dev/null 2>&1 &
            sleep 1
            /opt/AdGuardHome/AdGuardHome --no-check-update -c /opt/AdGuardHome/AdGuardHome.yaml 2>&1 &
            /usr/sbin/sniproxy -c /etc/sniproxy.conf -f 2>&1 &
            IPV6=$C
        fi
    fi
done
