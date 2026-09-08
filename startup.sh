#!/bin/bash
set -e

# 1. Start MySQL & Redis di background
service mysql start
service redis-server start

# 2. Setup database jika belum ada
if [ ! -f /var/www/pterodactyl/.env ]; then
    echo ">>> Membuat .env dan migrasi database..."
    cp .env.example .env
    sed -i "s|APP_URL=http://localhost|APP_URL=https://${RAILWAY_PUBLIC_DOMAIN}|g" .env
    sed -i 's/DB_HOST=127.0.0.1/DB_HOST=localhost/g' .env
    sed -i 's/DB_DATABASE=panel/DB_DATABASE=pterodactyl/g' .env
    sed -i 's/DB_USERNAME=pterodactyl/DB_USERNAME=root/g' .env
    sed -i 's/DB_PASSWORD=/DB_PASSWORD=/g' .env
    
    # Create database
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS pterodactyl;"
    
    # Generate key & migrate
    php artisan key:generate --force
    php artisan migrate --force --seed
    php artisan p:user:make --email=admin@panel.com --username=admin --password=Admin123! --no-interaction
    php artisan storage:link
fi

# 3. Start Supervisor (Nginx + PHP-FPM)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf