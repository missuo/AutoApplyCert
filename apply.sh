#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#================================================================
#	System Required: CentOS 6/7/8,Debian 8/9/10,Ubuntu 16/18/20
#	Description: Use acme.sh to apply SSL certificate automatically
#	Version: 1.1
#	Author: Vincent Young
# 	Telegram: https://t.me/missuo
#	Github: https://github.com/missuo/AutoApplyCert
#	Latest Update: Nov 13, 2021
#=================================================================

# Define some colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Guaranteed to run under ROOT
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}]: Please run this script with ROOT!" && exit 1

check_sys(){
	echo "Now start checking if your system supports"
	
	# Determine what Linux system it is
	if [[ -f /etc/redhat-release ]]; then
		release="Centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="Debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="Ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="Centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="Debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="Ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="Centos"
	fi
	
	# Depending on the system installation dependencies
	if [ $release = "Centos" ]
	then
		yum -y install curl wget socat
	elif [ $release = "Debian" ]
	then
		apt update -y && apt install -y curl wget socat
	elif [ $release = "Ubuntu" ]
	then
		apt update -y && apt install -y curl wget socat
	else
		echo -e "[${red}Error${plain}]: Current system not supported!"
		exit 1
	fi
}

# Install acme.sh
installAcme(){
    curl https://get.acme.sh | sh
    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
}

# Apply SSL certificate
applySSL(){
	check_sys
	installAcme
	read -p "Please enter your domain name: " domain
	[ -z "${domain}" ]
	echo ""
    ~/.acme.sh/acme.sh --issue -d ${domain} --standalone --keylength ec-256
    ~/.acme.sh/acme.sh --install-cert -d ${domain} --ecc --fullchain-file /etc/ssl/private/fullchain.pem --key-file /etc/ssl/private/privkey.pem
    chown -R nobody:nogroup /etc/ssl/private/
    echo "Your certificate is stored in the /etc/ssl/private/ directory"
}

update(){
	read -p "Please enter your domain name: " domain
	[ -z "${domain}" ]
	echo ""
	~/.acme.sh/acme.sh --renew -d ${domain} --ecc --force --fullchain-file /etc/ssl/private/fullchain.pem --key-file /etc/ssl/private/privkey.pem
    chown -R nobody:nogroup /etc/ssl/private/
    echo "Your certificate has been renewed and is stored in the /etc/ssl/private/ directory"
}

cancelrenew(){
	read -p "Please enter your domain name: " domain
	[ -z "${domain}" ]
	echo ""
	~/.acme.sh/acme.sh --cancel-auto-renew -d ${domain}
	echo "Your certificate has been cancelled for renewal"
}

start_menu(){
		clear
		echo && echo -e "Automatic SSL Certificate Application Made by missuo
Updates and Feedback: https://github.com/missuo/AutoApplyCert
————————————Mode————————————————
${green}1.${plain} Apply for a certificate
${green}2.${plain} Manual certificate renewal
${green}3.${plain} Cancel automatic renewal
${green}0.${plain} Exit
————————————————————————————————"
	read -p "Please enter the number: " num
	case "$num" in
	1)
		applySSL
		;;
	2)
		update
		;;
	3)
		cancelrenew
		;;
	0)
		exit 1
		;;
	*)
		clear
		echo -e "[${red}Error${plain}]:Please enter the correct number[0-3]"
		sleep 3s
		start_menu
		;;
	esac
}
start_menu 

