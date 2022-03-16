FROM php:7.4-fpm

LABEL maintainer="Diego Chaves <dfchaves@gmail.com>" 
LABEL version="0.1.0"

RUN ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

RUN apt-get update \
&& apt-get install --yes --no-install-recommends \
cron \
libbz2-dev \
libicu-dev \
libldap2-dev \
libpng-dev \
libxml2-dev \
libzip-dev \
nginx \
supervisor \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install \
    bz2 \
    ldap \
    mysqli \
    pdo_mysql \
    gd \
    intl \
    zip \
    opcache \
    exif \
    xmlrpc && \
pecl install -o -f apcu << "no" \
&& docker-php-ext-enable apcu

RUN rm -r /usr/local/etc/php/php.ini-development && \
rm -r /usr/local/etc/php-fpm.conf.default && \
rm -r /usr/local/etc/php-fpm.d/*.conf && \
mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
mv /usr/local/etc/php-fpm.d/www.conf.default /usr/local/etc/php-fpm.d/glpi.conf

RUN sed '/^\;\|^$/d' -i /usr/local/etc/php-fpm.conf && \
sed '/^\;\|^$/d' -i /usr/local/etc/php-fpm.d/glpi.conf && \
sed 's/\[www\]/[glpi]/' -i /usr/local/etc/php-fpm.d/glpi.conf && \
sed 's/listen = 127.0.0.1:9000/listen = \/run\/php-fpm.sock/' -i /usr/local/etc/php-fpm.d/glpi.conf && \
sed '/php-fpm.sock/a\
listen.owner = www-data\n\
listen.group = www-data\n\
listen.mode = 0660' \
-i /usr/local/etc/php-fpm.d/glpi.conf

RUN sed '/^\s*\#\|^$/d' -i /etc/nginx/nginx.conf &&\
    sed '/^\s*\#\|^$/d' -i /etc/nginx/fastcgi.conf &&\
    sed '/^\s*\#\|^$/d' -i /etc/nginx/snippets/fastcgi-php.conf &&\
    sed '/^\s*\#\|^$/d' -i /etc/nginx/sites-available/default &&\
    sed '/listen \[::\]:80/d' -i /etc/nginx/sites-available/default &&\
    sed 's/ index.nginx-debian.html//' -i /etc/nginx/sites-available/default &&\
    sed 's/index /&index.php /' -i /etc/nginx/sites-available/default &&\
    sed '/server_name _\;/a \
\\tlocation ~ /\\.ht {\n \
\t\tdeny all;\n \
\t}\n\
\tlocation ^~ /files/ {\n \
\t\tdeny all;\n \
\t}\n \
\tlocation ~ \\.php$ {\n \
\t\tinclude snippets/fastcgi-php.conf;\n \
\t\tfastcgi_pass unix:/run/php-fpm.sock;\n \
\t}' \
-i /etc/nginx/sites-available/default &&\
rm -rf /var/www/*

COPY confs/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh
CMD ["/usr/local/bin/start.sh"]
# CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
EXPOSE 80