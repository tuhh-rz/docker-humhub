#!/bin/bash

rsync -rc /tmp/humhub/* /usr/share/nginx/html

# Display PHP error's or not
if [[ "$ERRORS" != "1" ]] ; then
  sed -i -e "s/error_reporting =.*=/error_reporting = E_ALL/g" /etc/php/7.0/fpm/php.ini
  sed -i -e "s/display_errors =.*/display_errors = On/g" /etc/php/7.0/fpm/php.ini
fi

# Tweak nginx to match the workers to cpu's

procs=$(cat /proc/cpuinfo |grep processor | wc -l)
sed -i -e "s/worker_processes 5/worker_processes $procs/" /etc/nginx/nginx.conf


mkdir -p /run/php/

rm -rf /usr/share/nginx/html/protected/runtime/cache

su -s /bin/sh -c 'yes | php /usr/share/nginx/html/protected/yii migrate/up --includeModuleMigrations=1' www-data
chown -R www-data:www-data /usr/share/nginx/html/

# Start supervisord and services
/usr/bin/supervisord -n -c /etc/supervisord.conf
