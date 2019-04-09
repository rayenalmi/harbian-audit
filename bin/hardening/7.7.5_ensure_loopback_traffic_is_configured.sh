#!/bin/bash

#
# harbian audit 9 Hardening
#

#
# 7.7.5 Ensure loopback traffic is configured (Scored)
# Include ipv4 and ipv6
# Add this feature:Authors : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

IPS4=$(which iptables)
IPS6=$(which ip6tables)

# This function will be called if the script status is on enabled / audit mode
audit () {
	# Check the loopback interface to accept INPUT traffic.
    if [ $(${IPS4} -S | grep -c "^\-A INPUT \-i lo \-j ACCEPT") -ge 1 -o $(${IPS4} -S | grep -c "^\-A INPUT \-i 127.0.0.1 \-j ACCEPT") -ge 1 ]; then
		ok "Ip4tables loopback traffic INPUT has configured!"
		FNRET=0
	else
		crit "Ip4tables: loopback traffic INPUT is not configured!"
		if [ $(${IPS6} -S | grep -c "^\-A INPUT \-i lo \-j ACCEPT") -ge 1 -o $(${IPS6} -S | grep -c "^\-A INPUT \-i ::/0 \-j ACCEPT") -ge 1 ]; then
			ok "Ip6tables loopback traffic INPUT has configured!"
			FNRET=0
		else
			crit "Ip6tables: loopback traffic INPUT is not configured!"
			FNRET=1
		fi
	fi

	# Check the loopback interface to accept OUTPUT traffic.
    if [ $(${IPS4} -S | grep -c "^\-A OUTPUT \-o lo \-j ACCEPT") -ge 1 -o $(${IPS4} -S | grep -c "^\-A OUTPUT \-o 127.0.0.1 \-j ACCEPT") -ge 1 ]; then
		ok "Ip4tables loopback traffic OUTPUT has configured!"
		FNRET=0
	else
		crit "Ip4tables: loopback traffic OUTPUT is not configured!"
		if [ $(${IPS6} -S | grep -c "^\-A OUTPUT \-o lo \-j ACCEPT") -ge 1 -o $(${IPS6} -S | grep -c "^\-A OUTPUT \-o ::/0 \-j ACCEPT") -ge 1 ]; then
			ok "Ip6tables loopback traffic OUTPUT has configured!"
			FNRET=0
		else
			crit "Ip6tables: loopback traffic OUTPUT is not configured!"
			FNRET=2
		fi
	fi

	# all other interfaces to deny traffic to the loopback network.
    if [ $(${IPS4} -S | grep -c "^\-A INPUT \-s 127.0.0.0/8 \-j ACCEPT") -ge 1 ]; then
		crit "Ip4tables: loopback traffic INPUT deny from 127.0.0.0/8 is not configured!"
		if [ $(${IPS6} -S | grep -c "^\-A INPUT \-s ::1 \-j ACCEPT") -ge 1 ]; then
			crit "Ip6tables: loopback traffic INPUT deny from ::1 is not configured!"
			FNRET=3
		else
			ok "Ip6tables loopback traffic INPUT deny from ::1 has configured!"
			FNRET=0
		fi
	else
		ok "Ip4tables loopback traffic INPUT deny from 127.0.0.0/8 has configured!"
		FNRET=0
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	case $FNRET in 
	0)
        ok "Iptables/Ip6tables loopback traffic has configured!"
		;;
	1)
        warn "Iptables/Ip6tables loopback traffic INPUT is not configured! need the administrator to manually add it. Howto set: iptables/ip6tables -A INPUT -i lo -j ACCEPT"
		;;
	2)
        warn "Iptables/Ip6tables loopback traffic OUTPUT is not configured! need the administrator to manually add it. Howto set: iptables/ip6tables -A OUTPUT -o lo -j ACCEPT"
		;;
	3)
        warn "Iptables/Ip6tables loopback traffic INPUT deny from 127.0.0.0/8 is not configured! need the administrator to manually add it. Howto set: iptables/ip6tables -A INPUT -s 127.0.0.0/8 -j DROP"
		;;
	esac
}

# This function will check config parameters required
check_config() {
    :
}

# Source Root Dir Parameter
if [ -r /etc/default/cis-hardening ]; then
    . /etc/default/cis-hardening
fi
if [ -z "$CIS_ROOT_DIR" ]; then
     echo "There is no /etc/default/cis-hardening file nor cis-hardening directory in current environment."
     echo "Cannot source CIS_ROOT_DIR variable, aborting."
    exit 128
fi

# Main function, will call the proper functions given the configuration (audit, enabled, disabled)
if [ -r $CIS_ROOT_DIR/lib/main.sh ]; then
    . $CIS_ROOT_DIR/lib/main.sh
else
    echo "Cannot find main.sh, have you correctly defined your root directory? Current value is $CIS_ROOT_DIR in /etc/default/cis-hardening"
    exit 128
fi
