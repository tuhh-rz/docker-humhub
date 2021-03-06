FROM ubuntu:18.04

ARG VERSION=${VERSION}
ENV VERSION=$VERSION
RUN echo $VERSION

ARG DOWNLOAD=${DOWNLOAD}
ENV DOWNLOAD=$DOWNLOAD
RUN echo $DOWNLOAD

LABEL \
  de.tuhh.ci_repository_url=$CI_REPOSITORY_URL \
  de.tuhh.ci_commit_short_sha=$CI_COMMIT_SHORT_SHA \
  de.tuhh.build-date=$BUILD_DATE \
  de.tuhh.version=$VERSION \
  de.tuhh.eol=20230501


# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y upgrade

RUN apt-get install -y \
    cron \
    git \
    pwgen \
    rsync \
    supervisor \
    unzip \
    curl

# Update base image
# Add sources for latest nginx
# Install software requirements
RUN apt-get install -y software-properties-common && \
    nginx=stable && \
    add-apt-repository ppa:nginx/$nginx && \
    apt-get update && \
    apt-get upgrade -y && \
    BUILD_PACKAGES="nginx php-mysql php-apcu php-curl php-fpm php-gd php-intl php-mbstring php-memcache php-sqlite3 php-tidy php-xmlrpc php-xsl php-pgsql php-mongodb php-ldap php-zip" && \
    apt-get -y install $BUILD_PACKAGES && \
    apt-get remove --purge -y software-properties-common && \
    apt-get autoremove -y && \
    apt-get clean && \
    apt-get autoclean && \
    echo -n > /var/lib/apt/extended_states && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/man/?? && \
    rm -rf /usr/share/man/??_*

# tweak nginx config
RUN sed -i -e"s/worker_processes  1/worker_processes 5/" /etc/nginx/nginx.conf && \
    sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf && \
    sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf && \
    echo "daemon off;" >> /etc/nginx/nginx.conf

# tweak php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.2/fpm/php.ini && \
    sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.2/fpm/php.ini && \
    sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.2/fpm/php.ini && \
    sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.2/fpm/php-fpm.conf && \
    sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.2/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.2/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.2/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.2/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.2/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.2/fpm/pool.d/www.conf

# fix ownership of sock file for php-fpm
RUN sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.2/fpm/pool.d/www.conf && \
    find /etc/php/7.2/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} +

# # mycrypt conf
# RUN phpenmod mcrypt

# nginx site conf
RUN rm -Rf /etc/nginx/conf.d/* && \
    rm -Rf /etc/nginx/sites-enabled/default && \
    mkdir -p /etc/nginx/ssl/
ADD conf/nginx-site.conf /etc/nginx/sites-available/default
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Supervisor Config
ADD conf/supervisord.conf /etc/supervisord.conf

# Start Supervisord
ADD scripts/start.sh /start.sh
RUN chmod 755 /start.sh

# Download HumHub Community Edition
RUN curl $DOWNLOAD |\
    tar -xzC /opt && ln -s /opt/humhub-$VERSION /opt/humhub

# Crontab
#RUN echo "*/30 * * * * su -s /bin/bash -c '/usr/share/nginx/html/protected/yii cron/hourly' www-data >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
#RUN echo "0 18 * * * su -s /bin/bash -c '/usr/share/nginx/html/protected/yii cron/daily' www-data >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
RUN echo "0  6    * * *   www-data /usr/bin/php /usr/share/nginx/html/protected/yii cron/daily" >> /etc/crontab
RUN echo "13 *    * * *   www-data /usr/bin/php /usr/share/nginx/html/protected/yii cron/hourly" >> /etc/crontab
RUN echo "* * * * *   www-data /usr/bin/php /usr/share/nginx/html/protected/yii queue/run" >> /etc/crontab
RUN echo "* * * * *   www-data /usr/bin/php /usr/share/nginx/html/protected/yii cron/run" >> /etc/crontab

# Disable Errors / Debugging
#RUN rm /usr/share/nginx/html/index-test.php
#RUN sed -i "s/^defined('YII_DEBUG')/\/\/defined('YII_DEBUG')/" /usr/share/nginx/html/index.php
#RUN sed -i "s/^defined('YII_ENV')/\/\/defined('YII_ENV')/" /usr/share/nginx/html/index.php

RUN sed -i "s/^defined('YII_DEBUG')/\/\/defined('YII_DEBUG')/" /opt/humhub-$VERSION/index.php
RUN sed -i "s/^defined('YII_ENV')/\/\/defined('YII_ENV')/" /opt/humhub-$VERSION/index.php

# Run database migration tool
#RUN php /usr/share/nginx/html/protected/yii migrate/up --includeModuleMigrations=1

RUN find /opt/humhub-$VERSION ! -user www-data -exec chown www-data: {} +

# Expose Ports
EXPOSE 443
EXPOSE 80

CMD ["/bin/bash", "/start.sh"]
