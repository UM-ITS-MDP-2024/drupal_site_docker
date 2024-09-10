# Use PHP 8.3 Apache image as the base image
FROM php:8.3-apache

# Install necessary dependencies and Composer
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libwebp-dev \
    libonig-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    mariadb-client \
    unzip \
    zip \
    git \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
    gd \
    pdo_mysql \
    mbstring \
    xml \
    curl \
    opcache \
    && pecl install apcu && docker-php-ext-enable apcu  # Install and enable APCu

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add Composer's global bin directory to the PATH
ENV PATH="/root/.composer/vendor/bin:${PATH}"
ENV PATH="/var/www/html/vendor/bin:${PATH}"

# Use Composer to install Drupal (baked into the image)
RUN composer create-project drupal/recommended-project /var/www/html
RUN cd /var/www/html && composer require openai-php/client && composer require drush/drush && composer install

# Change Apache document root to /var/www/html/web (Drupal's web root)
RUN sed -i 's|/var/www/html|/var/www/html/web|g' /etc/apache2/sites-available/000-default.conf \
    && sed -i 's|/var/www/html|/var/www/html/web|g' /etc/apache2/apache2.conf

# Enable output buffering in the PHP configuration
RUN echo "output_buffering = 4096" >> /usr/local/etc/php/conf.d/docker-php-output_buffering.ini

# Enable mod_rewrite for Drupal
RUN a2enmod rewrite

# Ensure proper permissions
RUN chown -R www-data:www-data /var/www/html
RUN chmod -R 755 /var/www/html

# Copy the init script
COPY init-drupal.sh /usr/local/bin/init-drupal.sh

# Make the script executable
RUN chmod +x /usr/local/bin/init-drupal.sh

# Set the entrypoint to run the init script at runtime
ENTRYPOINT ["/usr/local/bin/init-drupal.sh"]
