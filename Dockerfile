FROM deckapp/nginx:v7.3
LABEL maintainer Naba Das <hello@get-deck.com>

# Persistent runtime dependencies
# Example RUN apk add --no-cache php7-openssl php7-sysvmsg php7-curl

RUN mkdir -p /app
RUN mkdir -p /application
RUN mkdir -p /var/preview
COPY default.conf /etc/nginx/conf.d/default.conf
COPY default.conf /app/default.conf
RUN wget -O /var/preview/index.html https://raw.githubusercontent.com/deck-app/stack-preview-screen/main/install/index.html
RUN sed -i "s#{SERVER_ROOT}#/var/preview#g" /etc/nginx/conf.d/default.conf
RUN sed -i "s#{SERVER_ROOT}#/application#g" /app/default.conf
RUN apk add --no-cache zip libzip-dev libmcrypt-dev
RUN apk add php7-pdo php7-zip php7-gd php7-xsl php7-pdo_mysql php7-intl php7-soap php7-sodium
RUN composer self-update --2

WORKDIR /var/www
#PHP display error enable or disable
ARG PHP_VERSION
COPY php.ini /etc/php7/php.ini
ARG DISPLAY_PHPERROR
RUN if [ ${DISPLAY_PHPERROR} = true ]; then \
sed -i "s#{DISPLAY}#On#g" /etc/php7/php.ini \
;else \
sed -i "s#{DISPLAY}#Off#g" /etc/php7/php.ini \
;fi

#Xdebug enable or disable
ARG XDEBUG
RUN if [ ${XDEBUG} = true ]; then \
apk add php8-pecl-xdebug \
&& echo "zend_extension=xdebug" >> /etc/php7/php.ini \
;fi

RUN mkdir -p /root/.composer/
COPY auth.json /root/.composer/auth.json
RUN composer self-update 1.10.12
RUN composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition /application/ 2.3.6


COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh
#CMD /docker-entrypoint.sh & /sbin/runit-wrapper
CMD [ "/sbin/runit-wrapper" ]