FROM pkpofficial/ojs:3_3_0-14

RUN apk add --no-cache \
    postgresql-dev \
    php-pgsql \
    php-pdo_pgsql \
    php-xml \
    php-mbstring \
    php-iconv \
    postgresql-client

RUN mkdir -p /var/lib/php/session \
    && chown -R apache:apache /var/lib/php/session \
    && chmod 1733 /var/lib/php/session

RUN mkdir -p /etc/php7/conf.d \
    && echo "session.save_path = /var/lib/php/session" \
    > /etc/php7/conf.d/session.ini

RUN mkdir -p /var/www/html/config-vol \
    && chown -R apache:apache /var/www/html/config-vol

RUN echo "SetEnvIf X-Forwarded-Proto https HTTPS=on" >> /etc/apache2/httpd.conf

COPY scripts/ojs-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
