#!/bin/bash

#CONFIG_FOLDER="/usr/local/share/humhub/config"
#if [ ! -d "$CONFIG_FOLDER" ]; then
#  ln -s "/usr/share/nginx/html/protected/config" "$CONFIG_FOLDER"
#else
#  rm -rf "/usr/share/nginx/html/protected/config"
#  ln -s  "$CONFIG_FOLDER" "/usr/share/nginx/html/protected/config"
#fi

SHARED_FOLDER="/usr/local/share/humhub"
if [ ! -d "$SHARED_FOLDER" ]; then
  mkdir -p "$SHARED_FOLDER"
fi

if [ "$(find $SHARED_FOLDER/uploads/ -prune -empty)" ]; then
  mv /usr/share/nginx/html/uploads/* $SHARED_FOLDER/uploads/
fi
rm -rf /usr/share/nginx/html/uploads
ln -s "$SHARED_FOLDER/uploads" "/usr/share/nginx/html/uploads"

if [ "$(find $SHARED_FOLDER/config/ -prune -empty)" ]; then
  mv /usr/share/nginx/html/protected/config/* $SHARED_FOLDER/config/
fi
rm -rf /usr/share/nginx/html/protected/config
ln -s "$SHARED_FOLDER/config" "/usr/share/nginx/html/protected/config"

chown -Rf www-data.www-data /usr/share/nginx/html/

# Disable Strict Host checking for non interactive git clones

#mkdir -p -m 0700 /root/.ssh
#echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config

# Setup git variables
#if [ ! -z "$GIT_EMAIL" ]; then
# git config --global user.email "$GIT_EMAIL"
#fi
#if [ ! -z "$GIT_NAME" ]; then
# git config --global user.name "$GIT_NAME"
# git config --global push.default simple
#fi

# Install Extras
#if [ ! -z "$DEBS" ]; then
# apt-get update
# apt-get install -y $DEBS
#fi

# Pull down code form git for our site!
#if [ ! -z "$GIT_REPO" ]; then
#  rm /usr/share/nginx/html/*
#  if [ ! -z "$GIT_BRANCH" ]; then
#    git clone -b $GIT_BRANCH $GIT_REPO /usr/share/nginx/html/
#  else
#    git clone $GIT_REPO /usr/share/nginx/html/
#  fi
#  chown -Rf nginx.nginx /usr/share/nginx/*
#fi

# Display PHP error's or not
if [[ "$ERRORS" != "1" ]] ; then
  sed -i -e "s/error_reporting =.*=/error_reporting = E_ALL/g" /etc/php5/fpm/php.ini
  sed -i -e "s/display_errors =.*/display_errors = On/g" /etc/php5/fpm/php.ini
fi

# Tweak nginx to match the workers to cpu's

procs=$(cat /proc/cpuinfo |grep processor | wc -l)
sed -i -e "s/worker_processes 5/worker_processes $procs/" /etc/nginx/nginx.conf

# Very dirty hack to replace variables in code with ENVIRONMENT values
#if [[ "$TEMPLATE_NGINX_HTML" == "1" ]] ; then
#  for i in $(env)
#  do
#    variable=$(echo "$i" | cut -d'=' -f1)
#    value=$(echo "$i" | cut -d'=' -f2)
#    if [[ "$variable" != '%s' ]] ; then
#      replace='\$\$_'${variable}'_\$\$'
#      find /usr/share/nginx/html -type f -exec sed -i -e 's/'${replace}'/'${value}'/g' {} \;
#    fi
#  done
#fi

# Again set the right permissions (needed when mounting from a volume)
chown -Rf www-data.www-data /usr/share/nginx/html/

# Start supervisord and services
/usr/bin/supervisord -n -c /etc/supervisord.conf
