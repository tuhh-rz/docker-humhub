#!/bin/bash

rsync -au /opt/humhub/ /usr/share/nginx/html

# Display PHP error's or not
if [[ "$ERRORS" != "1" ]]; then
    sed -i -e "s/error_reporting =.*=/error_reporting = E_ALL/g" /etc/php/7.2/fpm/php.ini
    sed -i -e "s/display_errors =.*/display_errors = On/g" /etc/php/7.2/fpm/php.ini
fi

# Tweak nginx to match the workers to cpu's
procs=$(grep -c processor /proc/cpuinfo)
sed -i -e "s/worker_processes 5/worker_processes $procs/" /etc/nginx/nginx.conf

mkdir -p /run/php/

rm -rf /usr/share/nginx/html/protected/runtime/cache

# http://docs.humhub.org/admin-updating.html
su -s /bin/sh -c 'yes | php /usr/share/nginx/html/protected/yii migrate/up --includeModuleMigrations=1' www-data
# su -s /bin/sh -c 'php /usr/share/nginx/html/protected/yii module/update-all' www-data

# Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
