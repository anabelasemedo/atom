FROM php:7.4-apache

# Instalar dependências necessárias
RUN apt-get update && apt-get install -y \
    wget \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    unzip \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install mysqli pdo pdo_mysql zip \
    && a2enmod rewrite

# Baixar e extrair o AtoM
RUN wget https://storage.accesstomemory.org/releases/atom-2.8.0.tar.gz \
    && tar -xzf atom-2.8.0.tar.gz -C /var/www/html --strip-components=1 \
    && rm atom-2.8.0.tar.gz

# Configurar permissões
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Copiar arquivo de configuração do AtoM
COPY ./init.sql /docker-entrypoint-initdb.d/

# Expor a porta 80
EXPOSE 80
