FROM ubuntu:18.04
MAINTAINER Visiture <devops@visiture.com>

RUN  apt-get update
RUN  apt-get install -y software-properties-common nodejs npm curl git unzip
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive  apt-get install -y php7.1 php7.1-gd php7.1-mysql php7.1-mcrypt php7.1-curl php7.1-intl php7.1-xsl php7.1-mbstring php7.1-zip php7.1-bcmath php7.1-iconv php7.1-soap

RUN  cd /tmp \
	&& curl -o ioncube.tar.gz http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
    && tar -xvvzf ioncube.tar.gz \
    && mkdir /usr/lib/php/20151012/ \
    && mv ioncube/ioncube_loader_lin_7.1.so /usr/lib/php/20151012/ \
    && rm -Rf ioncube.tar.gz ioncube \
    && echo "zend_extension=/usr/lib/php/20151012/ioncube_loader_lin_7.1.so" > /etc/php/7.1/cli/conf.d/00_docker-php-ext-ioncube_loader_lin_7.1.ini

WORKDIR /var/www/html

RUN  curl -sS https://getcomposer.org/installer | \
  php -- --install-dir=/usr/local/bin --filename=composer

#RUN composer global require hirak/prestissimo

RUN  echo 'memory_limit=-1' > /etc/php/7.1/cli/conf.d/php.ini
