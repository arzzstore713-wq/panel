# ============================================
# ALPHA-9999999 - PTERODACTYL PANEL (ALL-IN-ONE)
# Untuk Railway Trial Plan (1 Service)
# ============================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jakarta

# Install semua dependensi
RUN apt-get update && apt-get install -y \
    nginx \
    mariadb-server \
    redis-server \
    supervisor \
    curl \
    wget \
    git \
    unzip \
    gnupg \
    software-properties-common \
    && add-apt-repository ppa:ondrej/php -y \
    && apt-get update \
    && apt-get install -y \
    php8.3 \
    php8.3-fpm \
    php8.3-common \
    php8.3-cli \
    php8.3-gd \
    php8.3-mysql \
    php8.3-mbstring \
    php8.3-bcmath \
    php8.3-xml \
    php8.3-curl \
    php8.3-zip \
    php8.3-intl \
    php8.3-redis \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Download Pterodactyl Panel
WORKDIR /var/www
RUN git clone --depth 1 https://github.com/pterodactyl/panel.git pterodactyl
WORKDIR /var/www/pterodactyl
RUN composer install --no-dev --optimize-autoloader

# Set permission
RUN chown -R www-data:www-data /var/www/pterodactyl \
    && chmod -R 755 /var/www/pterodactyl/storage /var/www/pterodactyl/bootstrap/cache

# Copy konfigurasi Supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy konfigurasi Nginx
RUN rm -rf /etc/nginx/sites-enabled/default
COPY nginx.conf /etc/nginx/sites-available/pterodactyl
RUN ln -s /etc/nginx/sites-available/pterodactyl /etc/nginx/sites-enabled/

# Script startup (inisialisasi DB & migrasi)
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

EXPOSE 80

CMD ["/startup.sh"]