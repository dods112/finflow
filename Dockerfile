FROM php:8.2-apache

# =========================
# System dependencies
# =========================
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    zip \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# =========================
# PHP extensions (MySQL + PostgreSQL)
# =========================
RUN docker-php-ext-install \
    pdo_mysql \
    pdo_pgsql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd

# =========================
# Enable Apache modules
# =========================
RUN a2enmod rewrite

# =========================
# Install Composer
# =========================
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# =========================
# Working directory
# =========================
WORKDIR /var/www/html

# =========================
# Copy application
# =========================
COPY . .

# =========================
# Install dependencies
# =========================
RUN composer install --no-dev --optimize-autoloader

# =========================
# Permissions (Laravel required)
# =========================
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# =========================
# RUN DATABASE MIGRATIONS (ADDED THIS)
# =========================
RUN php artisan migrate --force

# =========================
# Render port configuration
# =========================
ENV PORT=10000

# Update Apache to use Render port
RUN sed -i "s/80/${PORT}/g" /etc/apache2/ports.conf

# =========================
# Apache Virtual Host (clean + safe)
# =========================
RUN printf '<VirtualHost *:%s>\n\
    DocumentRoot /var/www/html/public\n\
    <Directory /var/www/html/public>\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>\n' "$PORT" > /etc/apache2/sites-available/000-default.conf

# =========================
# Expose port for Render
# =========================
EXPOSE 10000

# =========================
# Startup command (safe for production)
# =========================
CMD php artisan config:clear && \
    php artisan cache:clear && \
    apache2-foreground
