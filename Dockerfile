FROM php:7.0.8-fpm

#################################### MARIADB #####################################################################

RUN echo "mysql-server mysql-server/root_password password root" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections

RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db && \
    echo 'deb http://mirrors.syringanetworks.net/mariadb/repo/10.1/ubuntu trusty main' >> /etc/apt/sources.list && \
    echo 'deb-src http://mirrors.syringanetworks.net/mariadb/repo/10.1/ubuntu trusty main' >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y mariadb-server pwgen && \
    rm -rf /var/lib/mysql/* && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#change bind address to 0.0.0.0
RUN sed -i -r 's/bind-address.*$/bind-address = 0.0.0.0/' /etc/mysql/my.cnf

ADD mariadb/create_mariadb_admin_user.sh /create_mariadb_admin_user.sh
ADD mariadb/run-mysql.sh /run-mysql.sh
RUN chmod 775 /*.sh

# Add VOLUMEs to allow backup of config and databases
VOLUME  ["/etc/mysql", "/var/lib/mysql"]

#Added to avoid in container connection to the database with mysql client error message "TERM environment variable not set"
ENV TERM dumb
ENV MARIADB_PASS admin

############################################################### PHP FPM ####################################################

RUN apt-get update \
  && apt-get install -y \
    cron \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    libxslt1-dev

RUN docker-php-ext-configure \
  gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/

RUN docker-php-ext-install \
  gd \
  intl \
  mbstring \
  mcrypt \
  pdo_mysql \
  soap \
  xsl \
  zip

RUN curl -sS https://getcomposer.org/installer | \
    php -- \
      --install-dir=/usr/local/bin \
      --filename=composer \
      --version=1.1.2

RUN mkdir -p /var/lib/php/session
RUN chmod 777 /var/lib/php/session

ENV PHP_MEMORY_LIMIT 2G
ENV PHP_PORT 9000
ENV PHP_PM dynamic
ENV PHP_PM_MAX_CHILDREN 10
ENV PHP_PM_START_SERVERS 4
ENV PHP_PM_MIN_SPARE_SERVERS 2
ENV PHP_PM_MAX_SPARE_SERVERS 6
ENV APP_MAGE_MODE default

COPY php/conf/www.conf /usr/local/etc/php-fpm.d/
COPY php/conf/php.ini /usr/local/etc/php/
COPY php/conf/php-fpm.conf /usr/local/etc/
COPY php/bin/* /usr/local/bin/

ENV NGINX_VERSION 1.10.2-1~jessie

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
	&& echo "deb http://nginx.org/packages/debian/ jessie nginx" >> /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
						ca-certificates \
						nginx=${NGINX_VERSION} \
						nginx-module-xslt \
						nginx-module-geoip \
						nginx-module-image-filter \
						nginx-module-perl \
						nginx-module-njs \
						gettext-base \
	&& rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log


ENV PHP_HOST 127.0.0.1
ENV PHP_PORT 9000

COPY ./nginx/conf/nginx.conf /etc/nginx/
COPY ./nginx/conf/default.conf /etc/nginx/conf.d/
COPY ./nginx/bin/start.sh /usr/local/bin/start.sh

################################## SUPERVISIOR #########################################################

RUN apt-get update && apt-get install -y supervisor
RUN mkdir -p /var/log/supervisor

COPY supervisior/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /srv/www

EXPOSE 80 443 3306

CMD ["/usr/bin/supervisord"]
