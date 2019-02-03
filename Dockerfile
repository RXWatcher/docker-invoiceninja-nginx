FROM invoiceninja/invoiceninja

LABEL maintainer="RXWatcher"

ENV NGINX_VERSION 1.13.12-1~stretch
ENV BUILD_DEPENDENCIES="\
        \
        wget" \
    RUN_DEPENDENCIES="\
		openssl \
		supervisor \
		cron \
		gnupg"

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y $BUILD_DEPENDENCIES $RUN_DEPENDENCIES \
	\
	&& ( \
	    wget http://nginx.org/keys/nginx_signing.key && apt-key add nginx_signing.key && rm -f nginx_signing.key \
	    && echo "deb http://nginx.org/packages/mainline/debian/ stretch nginx" >> /etc/apt/sources.list \
	    && apt-get update && apt-get install --no-install-recommends --no-install-suggests -y nginx=${NGINX_VERSION} \
	    && rm -f /etc/nginx/conf.d/* \
    ) \
    && ( \
        PUID=${PUID:-1000} \ 
        && PGID=${PGID:-1000} \ 
        && groupmod -o -g "$PGID" www-data \ 
        && usermod -o -u "$PUID" www-data \
        && crontab /var/crontab.txt \
        && chmod 600 /etc/crontab \
    ) \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $BUILD_DEPENDENCIES \
    && apt-get clean \
    && mkdir -p /var/log/nginx \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./crontab.txt /var/crontab.txt

RUN crontab /var/crontab.txt \
    && chmod 600 /etc/crontab \
    && mkdir -p /var/log/ninja_cron \
    && mkdir -p /var/log/supervisor \
    && touch /var/log/ninja_cron/reminders.log \
    && touch /var/log/ninja_cron/invoices.log

COPY ./supervisord.conf /etc/supervisord.conf
COPY ./nginx/conf.d/ /etc/nginx/conf.d
EXPOSE 80
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
