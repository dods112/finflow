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
# PHP extensions
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
# Enable Apache rewrite
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
# Copy project
# =========================
COPY . .

# =========================
# Install Laravel dependencies
# =========================
RUN composer install --no-dev --optimize-autoloader

# =========================
# Permissions
# =========================
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# =========================
# Render PORT setup (IMPORTANT)
# =========================
ENV PORT=10000

RUN sed -i 's/80/${PORT}/g' /etc/apache2/ports.conf

RUN echo "<VirtualHost *:${PORT}>
    DocumentRoot /var/www/html/public

    <Directory /var/www/html/public>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" > /etc/apache2/sites-available/000-default.conf

# =========================
# Expose Render port
# =========================
EXPOSE 10000

# =========================
# Startup (SAFE for Render)
# =========================
CMD php artisan config:clear && \
    php artisan cache:clear && \
    apache2-foreground
