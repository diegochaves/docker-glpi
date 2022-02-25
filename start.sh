#!/bin/bash

GLPI_VERSION=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep tag_name | cut -d '"' -f 4)
GLPI_URL=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/tags/${GLPI_VERSION} | python3 -c "import sys, json; print(json.load(sys.stdin)['assets'][0]['browser_download_url'])")

curl -L $GLPI_URL --output /tmp/glpi.tgz
tar -xzf /tmp/glpi.tgz -C /var/www/