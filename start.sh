#!/bin/bash

[[ "${DOMAIN}" ]] && sed "s/server_name _;/server_name $DOMAIN;/" -i /etc/nginx/sites-available/default;

if [[ -z "${TZ}" ]]; then echo "TZ is unset"; 
else 
    echo "date.timezone = \"$TZ\"" > /usr/local/etc/php/conf.d/timezone.ini;
fi

[[ ! "$GLPI_VERSION" ]] \
	&& GLPI_VERSION=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep tag_name | cut -d '"' -f 4)

GLPI_URL=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/tags/${GLPI_VERSION} | python3 -c "import sys, json; print(json.load(sys.stdin)['assets'][0]['browser_download_url'])")
curl -L $GLPI_URL --output /tmp/glpi.tgz
tar -xzf /tmp/glpi.tgz -C /var/www/
mv /var/www/glpi/* /var/www/html/
rm -Rf /var/www/glpi
rm /tmp/glpi.tgz
chown -R www-data:www-data /var/www/html
echo "*/2 * * * * www-data /usr/local/bin/php /var/www/html/front/cron.php &>/dev/null" >> /etc/cron.d/glpi

/var/www/html/bin/console glpi:database:configure -H database -d glpi -u glpi -p glpi -n -q

[[ "$UPDATE" ]] \
    && /var/www/html/bin/console glpi:database:update -n -q

/usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf