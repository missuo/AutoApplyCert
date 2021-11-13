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

# 定义一些颜色
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# 保证在ROOT下运行
[[ $EUID -ne 0 ]] && echo -e "[${red}错误${plain}]请以ROOT运行本脚本！" && exit 1

check_sys(){
	echo "现在开始检查你的系统是否支持"
	
	# 判断是什么Linux系统
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
	
	# 根据系统安装依赖
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
		echo -e "[${red}错误${plain}]不支持当前系统"
		exit 1
	fi
}

# 安装acme.sh
installAcme(){
    curl https://get.acme.sh | sh
    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
}

# 申请证书
applySSL(){
	check_sys
	installAcme
	read -p "请输入你的域名:" domain
	[ -z "${domain}" ]
	echo ""
    ~/.acme.sh/acme.sh --issue -d ${domain} --standalone --keylength ec-256
    ~/.acme.sh/acme.sh --install-cert -d ${domain} --ecc --fullchain-file /etc/ssl/private/fullchain.pem --key-file /etc/ssl/private/privkey.pem
    chown -R nobody:nogroup /etc/ssl/private/
    echo "你的证书被存放在/etc/ssl/private/目录下"
}

update(){
	read -p "请输入你的域名:" domain
	[ -z "${domain}" ]
	echo ""
	~/.acme.sh/acme.sh --renew -d ${domain} --ecc --force --fullchain-file /etc/ssl/private/fullchain.pem --key-file /etc/ssl/private/privkey.pem
    chown -R nobody:nogroup /etc/ssl/private/
    echo "你的证书已更新完并且被存放在/etc/ssl/private/目录下"
}

cancelrenew(){
	read -p "请输入你的域名:" domain
	[ -z "${domain}" ]
	echo ""
	~/.acme.sh/acme.sh --cancel-auto-renew -d ${domain}
	echo "你的证书已取消续签"
}

start_menu(){
		clear
		echo && echo -e "自动申请SSL证书 Made by missuo
更新内容及反馈： https://github.com/missuo/AutoApplyCert
————————————模式选择————————————
${green}1.${plain} 申请证书
${green}2.${plain} 手动更新证书
${green}3.${plain} 取消自动续期
${green}0.${plain} 退出脚本
————————————————————————————————"
	read -p "请输入数字: " num
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
		echo -e "[${red}错误${plain}]:请输入正确数字[0-3]"
		sleep 5s
		start_menu
		;;
	esac
}
start_menu 

