#!/bin/bash

set -e
set -x

# Cleanup
rm -rf /var/www/html/*

# Copy frontend files
cp /speedtest/*.js /var/www/html/

# Copy favicon
cp /speedtest/favicon.ico /var/www/html/

# Set up backend side for standlone modes
if [ "$MODE" == "standalone" ]; then
  cp -r /speedtest/backend/ /var/www/html/backend
  if [ ! -z "$IPINFO_APIKEY" ]; then
    sed -i s/\$IPINFO_APIKEY\ =\ \'\'/\$IPINFO_APIKEY\ =\ \'$IPINFO_APIKEY\'/g /var/www/html/backend/getIP_ipInfo_apikey.php
  fi
fi

if [ "$MODE" == "backend" ]; then
  cp -r /speedtest/backend/* /var/www/html
  if [ ! -z "$IPINFO_APIKEY" ]; then
    sed -i s/\$IPINFO_APIKEY\ =\ \'\'/\$IPINFO_APIKEY\ =\ \'$IPINFO_APIKEY\'/g /var/www/html/getIP_ipInfo_apikey.php
  fi
fi

# Set up index.php for frontend-only or standalone modes
if [ "$MODE" == "frontend" ]; then
  cp /speedtest/frontend.php /var/www/html/index.php
elif [ "$MODE" == "standalone" ]; then
  cp /speedtest/standalone.php /var/www/html/index.php
fi

# Apply Telemetry settings when running in standalone or frontend mode and telemetry is enabled
if [[ "$TELEMETRY" == "true" && ( "$MODE" == "frontend" || "$MODE" == "standalone" ) ]]; then
  cp -r /speedtest/results /var/www/html/results

  sed -i s/\$db_type\ =\ \'.*\'/\$db_type\ =\ \'sqlite\'\/g /var/www/html/results/telemetry_settings.php
  sed -i s/\$Sqlite_db_file\ =\ \'.*\'/\$Sqlite_db_file=\'\\\/database\\\/db.sql\'/g /var/www/html/results/telemetry_settings.php
  sed -i s/\$stats_password\ =\ \'.*\'/\$stats_password\ =\ \'$PASSWORD\'/g /var/www/html/results/telemetry_settings.php

  if [ "$ENABLE_ID_OBFUSCATION" == "true" ]; then
    sed -i s/\$enable_id_obfuscation\ =\ .*\;/\$enable_id_obfuscation\ =\ true\;/g /var/www/html/results/telemetry_settings.php
  fi

  if [ "$REDACT_IP_ADDRESSES" == "true" ]; then
    sed -i s/\$redact_ip_addresses\ =\ .*\;/\$redact_ip_addresses\ =\ true\;/g /var/www/html/results/telemetry_settings.php
  fi

  mkdir -p /database/
  chown www-data /database/
fi

chown -R www-data /var/www/html/*

# Allow selection of Apache port for network_mode: host

sed -i "s/^Listen 80\$/Listen $HTTP_PORT/g" /etc/apache2/ports.conf
sed -i "s/Listen 443\$/Listen $HTTPS_PORT/g" /etc/apache2/ports.conf
sed -i "s/*:80>/*:$HTTP_PORT>/g" /etc/apache2/sites-available/000-default.conf 

# HTTPS configuration 
# Note: coexistence of both HTTP and HTTPS is not considered yet

if [[ "$ENABLE_HTTPS" == "true" && "$DISABLE_HTTP" == "true" ]]; then
  sed -i "s/^Listen $HTTP_PORT\$/# Listen $HTTP_PORT/g" /etc/apache2/ports.conf
  sed -i "s/*:$HTTP_PORT>/*:$HTTPS_PORT>/g" /etc/apache2/sites-available/000-default.conf 

  SEARCH_PATTERN="/<\/VirtualHost>/"

  sed -i "${SEARCH_PATTERN} {x;p;x;}" /etc/apache2/sites-available/000-default.conf
  sed -i "${SEARCH_PATTERN} i \\\tSSLEngine on" /etc/apache2/sites-available/000-default.conf
  sed -i "${SEARCH_PATTERN} i \\\tSSLCertificateFile \/etc\/apache2\/certificate\/cert.pem" /etc/apache2/sites-available/000-default.conf
  sed -i "${SEARCH_PATTERN} i \\\tSSLCertificateKeyFile \/etc\/apache2\/certificate\/privkey.pem" /etc/apache2/sites-available/000-default.conf

  SEARCH_PATTERN="/<Directory \/var\/www\/>/"

  sed -i "${SEARCH_PATTERN} i <Directory \/var\/www\/html\/>" /etc/apache2/apache2.conf
  sed -i "${SEARCH_PATTERN} i \\\tAllowOverride All" /etc/apache2/apache2.conf
  sed -i "${SEARCH_PATTERN} i <\/Directory>" /etc/apache2/apache2.conf
  sed -i "${SEARCH_PATTERN} {x;p;x;}" /etc/apache2/apache2.conf

  if [ ! -d "$CERT_PATH" ]; then
    mkdir $CERT_PATH
  fi

  a2enmod ssl
  a2enmod rewrite

fi

echo "Done, Starting APACHE"

# This runs apache
apache2-foreground

# Debug
# tail -f /dev/null