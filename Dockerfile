# from https://www.drupal.org/docs/8/system-requirements/drupal-8-php-requirements
FROM php:7.4-apache-buster
# TODO switch to buster once https://github.com/docker-library/php/issues/865 is resolved in a clean way (either in the PHP image or in PHP itself)

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# install the PHP extensions we need
RUN set -eux; \
	\
	if command -v a2enmod; then \
		a2enmod rewrite; \
	fi; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libfreetype6-dev \
		libjpeg-dev \
		libpng-dev \
		libpq-dev \
		libzip-dev \
	; \
	\
	docker-php-ext-install -j "$(nproc)" \
		gd \
		opcache \
		pdo_mysql \
		pdo_pgsql \
		zip \
	; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=4086'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini


RUN { \
echo 'memory_limit = -1'; } > /usr/local/etc/php/php.ini

WORKDIR /var/www/html

# https://www.drupal.org/node/3060/release
ENV DRUPAL_VERSION 9.2.8
ENV DRUPAL_MD5 911a8b35d60b03d1d481c263024d9526

RUN set -eux; \
	curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz; \
	echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c -; \
	tar -xz --strip-components=1 -f drupal.tar.gz; \
	rm drupal.tar.gz; \
	chown -R www-data:www-data sites modules themes

# vim:set ft=dockerfile:

# Install CLI dependencies
RUN apt-get update && apt-get install -y mariadb-client curl git vim \
	&& apt-get clean

# Install Composer
RUN echo "allow_url_fopen = On" > /usr/local/etc/php/conf.d/drupal-01.ini
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin -- --filename=composer --version=2.0.12

# Create directories for Drupal
RUN mkdir -p /tmp/drupal && chown www-data:www-data /tmp/drupal
RUN chown www-data:www-data /var/www
WORKDIR /var/www/drupal

# Config
ENV DOCROOT=/var/www/drupal/web
ADD apache.conf /etc/apache2/sites-enabled/000-default.conf
ADD bashrc.sh /var/www/.bashrc
ADD drushrc.php /etc/drush/drushrc.php

RUN \
        pecl install xdebug; \
        docker-php-ext-enable xdebug;

