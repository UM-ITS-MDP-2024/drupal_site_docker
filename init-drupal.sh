#!/bin/bash

# Directory where Drupal is installed
DRUPAL_DIR="/var/www/html/web"

# If settings.php does not exist, complete the installation
if [ ! -f "$DRUPAL_DIR/sites/default/settings.php" ]; then
  echo "No settings.php found, proceeding with Drupal installation..."

  # Ensure files directory exists and set permissions
  mkdir -p $DRUPAL_DIR/sites/default/files
  chown -R www-data:www-data $DRUPAL_DIR
  chmod -R 755 $DRUPAL_DIR
  
  # Copy default settings and set permissions
  cp $DRUPAL_DIR/sites/default/default.settings.php $DRUPAL_DIR/sites/default/settings.php
  chmod 644 $DRUPAL_DIR/sites/default/settings.php
  
  # Wait for the database to be ready
  echo "Waiting for MySQL to be ready..."
  until mysql -h"$DRUPAL_DB_HOST" -u"$DRUPAL_DB_USER" -p"$DRUPAL_DB_PASSWORD" -e 'show databases;' &> /dev/null; do
    echo -n "."; sleep 1
  done
  echo "MySQL is ready."
  
  # Install Drupal using Drush
  echo "Installing Drupal with Drush..."

  drush site-install standard \
    --db-url="mysql://${DRUPAL_DB_USER}:${DRUPAL_DB_PASSWORD}@${DRUPAL_DB_HOST}/${DRUPAL_DB_NAME}" \
    --account-name=admin \
    --account-pass=admin \
    --site-name="My Drupal Site" \
    --yes

  # Adjust file permissions after installation
  chown -R www-data:www-data $DRUPAL_DIR
else
  echo "Drupal is already installed, skipping installation."
fi

# Enable Apache mod_rewrite
a2enmod rewrite

# Start Apache in the foreground
apache2-foreground
