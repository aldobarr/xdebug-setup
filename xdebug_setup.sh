#!/bin/bash

NO_PROXY=0
VERSION="3.0.3"
function usage() {
	echo "Usage $0
	[-v version]
	[-n no dbgpProxy]
	[-h help]"
}

while getopts hv:n opt; do
	case $opt in 
		h) usage; exit ;;
		v) VERSION=$OPTARG ;;
		n) NO_PROXY=1 ;;
	esac
done

if [ "$EUID" -ne 0 ]
then
	echo "Please run as root"
	exit
fi

if ! command -v php &> /dev/null
then
	echo "php could not be found"
	exit
fi

if ! command -v wget &> /dev/null
then
	echo "wget could not be found"
	exit
fi

INSTALL_PROGRAMS="php-dev autoconf automake"
if [ $NO_PROXY -ne 1 ]
then
	INSTALL_PROGRAMS="$INSTALL_PROGRAMS supervisor"
fi

PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;")
XDEBUG_INSTALL_DIR=$(php -r 'echo ini_get("extension_dir");')
PHP_MODS_DIR="/etc/php/$PHP_VERSION/mods-available"

XDEBUG_CONF="zend_extension = xdebug.so
xdebug.mode = debug
xdebug.client_port = 9003
xdebug.start_with_request = trigger
xdebug.output_dir = /tmp/xdebug
xdebug.log_level = 0"

SUPERVISOR_CONF="[program:dbgpProxy]
command=/usr/bin/dbgpProxy -s 127.0.0.1:9003
autostart=true
autorestart=true
stderr_logfile=/var/log/dbgpProxy.error
stdout_logfile=/var/log/dbgpProxy.log"

if [ ! -d $XDEBUG_INSTALL_DIR ]
then
	echo "PHP Extensions Directory is missing"
	exit
fi

if [ ! -d $PHP_MODS_DIR ]
then
	echo "PHP Module Directory is missing"
	exit
fi

apt update
apt install -y $INSTALL_PROGRAMS

if [ ! -d /tmp/xdebug_install ]
then
	mkdir /tmp/xdebug_install
fi

cd /tmp/xdebug_install
wget https://xdebug.org/files/xdebug-$VERSION.tgz
tar -xzf xdebug-$VERSION.tgz
cd xdebug-$VERSION
phpize
./configure
make

if [ -f "$XDEBUG_INSTALL_DIR/xdebug.so" ]
then
	rm -f /etc/tmpfiles.d/xdebug-cleanup.conf
fi

cp modules/xdebug.so $XDEBUG_INSTALL_DIR
chmod 644 "$XDEBUG_INSTALL_DIR/xdebug.so"

if [ -f "$PHP_MODS_DIR/xdebug.ini" ]
then
	rm -f /etc/tmpfiles.d/xdebug-cleanup.conf
fi

touch "$PHP_MODS_DIR/xdebug.ini"
echo "$XDEBUG_CONF" >> "$PHP_MODS_DIR/xdebug.ini"
chmod 644 "$PHP_MODS_DIR/xdebug.ini"

if [ ! -d /tmp/xdebug ]
then
	mkdir /tmp/xdebug
fi

chmod 777 /tmp/xdebug

if [ -f /etc/tmpfiles.d/xdebug-cleanup.conf ]
then
	rm -f /etc/tmpfiles.d/xdebug-cleanup.conf
fi

touch /etc/tmpfiles.d/xdebug-cleanup.conf
echo "d /tmp/xdebug 0777 root root 10m" >> /etc/tmpfiles.d/xdebug-cleanup.conf
chmod 644 /etc/tmpfiles.d/xdebug-cleanup.conf

phpenmod xdebug
systemctl restart apache2

if [ $NO_PROXY -ne 1 ]
then
	if [ -f /usr/bin/dbgpProxy ]
	then
		rm -f /usr/bin/dbgpProxy
	fi

	wget https://xdebug.org/files/binaries/dbgpProxy
	chmod +x dbgpProxy
	mv dbgpProxy /usr/bin/

	if [ -f /etc/supervisor/conf.d/dbgpProxy.conf ]
	then
		rm -f /etc/supervisor/conf.d/dbgpProxy.conf
	fi

	touch /etc/supervisor/conf.d/dbgpProxy.conf
	echo "$SUPERVISOR_CONF" >> /etc/supervisor/conf.d/dbgpProxy.conf
	chmod 644 /etc/supervisor/conf.d/dbgpProxy.conf

	supervisorctl reread
	supervisorctl update
fi

cd ../
rm -rf /tmp/xdebug_install

echo "done"
