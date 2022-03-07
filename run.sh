#!/bin/bash

set -e

# return nonzero unless $1 contains only digits, leading zeroes not allowed
is_numeric() {
    case "$1" in
        "" | *[![:digit:]]* | 0[[:digit:]]* ) return 1;;
    esac
}

# return nonzero unless $1 contains only hexadecimal digits
is_hex() {
    case "$1" in
        "" | *[![:xdigit:]]* ) return 1;;
    esac
}

# return nonzero unless $1 is a valid IPv4 address with optional trailing subnet mask in the format /<bits>
is_ip4() {

    # fail if $1 is not set, move it into a variable so we can mangle it 
    [ -n "$1" ] || return
    IP4_ADDR="$1"

    # handle subnet mask for any address containing a /
    case "$IP4_ADDR" in
        *"/"* ) # set $IP4_GROUP to the number of bits (the characters after the last /)
                IP4_GROUP="${IP4_ADDR##*"/"}"

                # return failure unless $IP4_GROUP is a positive integer less than or equal to 32
                is_numeric "$IP4_GROUP" && [ "$IP4_GROUP" -le 32 ] || return

                # remove the subnet mask from the address
                IP4_ADDR="${IP4_ADDR%"/$IP4_GROUP"}";;
    esac

    # backup current $IFS, set $IFS to . as that's what separates digit groups (octets)
    IP4_IFS="$IFS"; IFS="."

    # initialize count
    IP4_COUNT=0

    # loop over digit groups
    for IP4_GROUP in $IP4_ADDR ;do  
        # return failure if group is not numeric or if it is greater than 255
        ! is_numeric "$IP4_GROUP" || [ "$IP4_GROUP" -gt 255 ] && IFS="$IP4_IFS" && return 1

        # increment count
        IP4_COUNT=$(( IP4_COUNT + 1 ))

        # the following line will prevent the loop continuing to run for invalid addresses with many occurrences of .
        # this makes no difference to the result, but may improve performance when validating many such invalid strings
        [ "$IP4_COUNT" -le 4 ] || break
    done

    # restore $IFS
    IFS="$IP4_IFS"

    # return success if there are 4 digit groups, otherwise return failure
    [ "$IP4_COUNT" -eq 4 ]
}

# return nonzero unless $1 is a valid IPv6 address with optional trailing subnet mask in the format /<bits>
is_ip6() {
    # fail if $1 is not set, move it into a variable so we can mangle it 
    [ -n "$1" ] || return
    IP6_ADDR="$1"

    # handle subnet mask for any address containing a /
    case "$IP6_ADDR" in
        *"/"* ) # set $IP6_GROUP to the number of bits (the characters after the last /)
                IP6_GROUP="${IP6_ADDR##*"/"}"

                # return failure unless $IP6_GROUP is a positive integer less than or equal to 128
                is_numeric "$IP6_GROUP" && [ "$IP6_GROUP" -le 128 ] || return

                # remove the subnet mask from the address
                IP6_ADDR="${IP6_ADDR%"/$IP6_GROUP"}";;
    esac

    # perform some preliminary tests and check for the presence of ::
    case "$IP6_ADDR" in
        # failure cases
        # *"::"*"::"*  matches multiple occurrences of ::
        # *":::"*      matches three or more consecutive occurrences of :
        # *[^:]":"     matches trailing single :
        # *"."*":"*    matches : after .
        *"::"*"::"* | *":::"* | *[^:]":" | *"."*":"* ) return 1;;

        *"::"* ) # set flag $IP6_EXPANDED to true, to allow for a variable number of digit groups
                 IP6_EXPANDED=0

                 # because :: should not be used for remove a single zero group we start the group count at 1 when :: exists
                 # NOTE This is a strict interpretation of the standard, applications should not generate such IP addresses but (I think)
                 #      they are in fact technically valid. To allow addresses with single zero groups replaced by :: set $IP6_COUNT to 
                 #      zero after this case statement instead
                 IP6_COUNT=1;; 

        *      ) # set flag $IP6_EXPANDED to false, to forbid a variable number of digit groups
                 IP6_EXPANDED=""

                 # initialize count
                 IP6_COUNT=0;;
    esac
    # backup current $IFS, set $IFS to : to delimit digit groups
    IP6_IFS="$IFS"; IFS=":"

    # loop over digit groups
    for IP6_GROUP in $IP6_ADDR ;do
        # if this is an empty group then increment count and process next group
        [ -z "$IP6_GROUP" ] && IP6_COUNT=$(( IP6_COUNT + 1 )) && continue

        # handle dotted quad notation groups
        case "$IP6_GROUP" in
            *"."* ) # return failure if group is not a valid IPv4 address
                    # NOTE a subnet mask is added to the group to ensure we are matching addresses only, not ranges
                    ! is_ip4 "$IP6_GROUP/1" && IFS="$IP6_IFS" && return 1

                    # a dotted quad refers to 32 bits, the same as two 16 bit digit groups, so we increment the count by 2
                    IP6_COUNT=$(( IP6_COUNT + 2 ))

                    # we can stop processing groups now as we can be certain this is the last group, : after . was caught as a failure case earlier
                    break;;
        esac

        # if there are more than 4 characters or any character is not a hex digit then return failure
        [ "${#IP6_GROUP}" -gt 4 ] || ! is_hex "$IP6_GROUP" && IFS="$IP6_IFS" && return 1

        # increment count
        IP6_COUNT=$(( IP6_COUNT + 1 ))

        # the following line will prevent the loop continuing to run for invalid addresses with many occurrences of a single :
        # this makes no difference to the result, but may improve performance when validating many such invalid strings
        [ "$IP6_COUNT" -le 8 ] || break
    done

    # restore $IFS
    IFS="$IP6_IFS"

    # if this address contained a :: and it has less than or equal to 8 groups then return success 
    [ "$IP6_EXPANDED" = "0" ] && [ "$IP6_COUNT" -le 8 ] && return

    # if this address contained exactly 8 groups then return success, otherwise return failure
    [ "$IP6_COUNT" -eq 8 ]
}

IPV4="203.0.113.0"
IPV6="2001:db8:ffff:ffff:ffff:ffff:ffff:ffff"

if [ $DISABLE_V4 -eq 1 ];then
    sed -i "s/$IPV4/A/g" /opt/AdGuardHome/AdGuardHome.yaml
    IPV4="A"
fi

if [ $DISABLE_V6 -eq 1 ];then
    sed -i "s/$IPV6/AAAA/g" /opt/AdGuardHome/AdGuardHome.yaml
    sed -i "s/ipv6_first/ipv4_first/g" /etc/sniproxy.conf
    IPV6="AAAA"
fi

# 造一个错误命令来进入循环
CHANGE_PWD=1
while [ $CHANGE_PWD -eq 1 ] 
do
    PASSHASH=$(htpasswd -bnBC 10 "" $PASSWORD | tr -d ':\n' | sed 's/$2y/$2a/')
    sed -i "s/\$2a\$10\$UL51kOUMX6uwmI1y8ddCje.5IQ0.FM4aeTbjC5n3N8Vu9QFZnX.Qq/${PASSHASH}/g" /opt/AdGuardHome/AdGuardHome.yaml >/dev/null 2>&1
    if [ $? -eq 0 ];then
       CHANGE_PWD=0
    fi
done

CHANGE_IP=0
while [[ true ]]; do
    sleep 1
    
    while true; do
        C=$(curl -4 ifconfig.co 2>/dev/null)
        is_ip4 $C
        if [ $? -eq 0 ];then
            if [[ "$IPV4" != "$C" ]];then
                CHANGE_IP=1
                sed -i "s/$IPV4/$C/g" /opt/AdGuardHome/AdGuardHome.yaml
                IPV4=$C
            fi
        fi
        [ $? -eq 0 ] && break
        sleep 1
    done

    while true; do
        C=$(curl -6 ifconfig.co 2>/dev/null)
        is_ip6 $C
        if [ $? -eq 0 ];then
            if [[ "$IPV6" != "$C" ]];then
                CHANGE_IP=1
                sed -i "s/$IPV6/$C/g" /opt/AdGuardHome/AdGuardHome.yaml
                IPV6=$C
            fi
        fi
        [ $? -eq 0 ] && break
        sleep 1
    done

    if [ $CHANGE_IP -eq 1 ];then
        killall -9 AdGuardHome >/dev/null 2>&1 &
        killall -9 sniproxy >/dev/null 2>&1 &
        sleep 1
        /opt/AdGuardHome/AdGuardHome --no-check-update -c /opt/AdGuardHome/AdGuardHome.yaml 2>&1 &
        /usr/sbin/sniproxy -c /etc/sniproxy.conf -f 2>&1 &
        CHANGE_IP=0
    fi
done
