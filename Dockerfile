# Use uma imagem base oficial do Ubuntu
FROM ubuntu:20.04

# Variáveis de ambiente para prevenir prompts de instalação
ENV DEBIAN_FRONTEND=noninteractive

# Atualize o sistema e instale dependências
RUN apt-get update && \
    apt-get install -y \
    mysql-server \
    openjdk-11-jre-headless \
    apt-transport-https \
    software-properties-common \
    php7.4 \
    php7.4-cli \
    php7.4-curl \
    php7.4-json \
    php7.4-ldap \
    php7.4-mysql \
    php7.4-opcache \
    php7.4-readline \
    php7.4-xml \
    php7.4-mbstring \
    php7.4-xsl \
    php7.4-zip \
    php-apcu \
    php-apcu-bc \
    php-memcache \
    gearman-job-server \
    fop \
    libsaxon-java \
    imagemagick \
    ghostscript \
    poppler-utils \
    ffmpeg \
    wget \
    gnupg \
    nginx \
    git \
    composer \
    npm \
    nano && \
    apt-get clean

# Adicione repositório do Elasticsearch
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
    echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-5.x.list && \
    apt-get update && \
    apt-get install -y elasticsearch && \
    systemctl enable elasticsearch

# Configurações do MySQL
RUN echo "[mysqld]\nsql_mode=ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION\noptimizer_switch='block_nested_loop=off'" >> /etc/mysql/conf.d/mysqld.cnf && \
    service mysql restart

# Baixar e configurar o AtoM
RUN mkdir -p /usr/share/nginx/atom && \
    wget https://storage.accesstomemory.org/releases/atom-2.8.0.tar.gz && \
    tar xzf atom-2.8.0.tar.gz -C /usr/share/nginx/atom --strip 1 && \
    rm atom-2.8.0.tar.gz

# Instalar dependências do Composer e Node.js
RUN cd /usr/share/nginx/atom && \
    composer install --no-dev && \
    npm install && \
    npm run build

# Configurações do PHP-FPM
RUN echo "[atom]\nuser = www-data\ngroup = www-data\nlisten = /run/php7.4-fpm.atom.sock\nlisten.owner = www-data\nlisten.group = www-data\nlisten.mode = 0600\npm = dynamic\npm.max_children = 30\npm.start_servers = 10\npm.min_spare_servers = 10\npm.max_spare_servers = 10\npm.max_requests = 200\nchdir = /\nphp_admin_value[expose_php] = off\nphp_admin_value[allow_url_fopen] = on\nphp_admin_value[memory_limit] = 512M\nphp_admin_value[max_execution_time] = 120\nphp_admin_value[post_max_size] = 72M\nphp_admin_value[upload_max_filesize] = 64M\nphp_admin_value[max_file_uploads] = 10\nphp_admin_value[cgi.fix_pathinfo] = 0\nphp_admin_value[display_errors] = off\nphp_admin_value[display_startup_errors] = off\nphp_admin_value[html_errors] = off\nphp_admin_value[session.use_only_cookies] = 0\nphp_admin_value[apc.enabled] = 1\nphp_admin_value[apc.shm_size] = 64M\nphp_admin_value[apc.num_files_hint] = 5000\nphp_admin_value[apc.stat] = 0\nphp_admin_value[opcache.enable] = 1\nphp_admin_value[opcache.memory_consumption] = 192\nphp_admin_value[opcache.interned_strings_buffer] = 16\nphp_admin_value[opcache.max_accelerated_files] = 4000\nphp_admin_value[opcache.validate_timestamps] = 0\nphp_admin_value[opcache.fast_shutdown] = 1\nenv[ATOM_DEBUG_IP] = \"10.10.10.10,127.0.0.1\"\nenv[ATOM_READ_ONLY] = \"off\"" > /etc/php/7.4/fpm/pool.d/atom.conf && \
    service php7.4-fpm restart

# Configurações do Nginx
RUN rm /etc/nginx/sites-enabled/default && \
    echo "upstream atom {\n   server unix:/run/php7.4-fpm.atom.sock;\n}\n\nserver {\n   listen 80;\n   root /usr/share/nginx/atom;\n   server_name _;\n\n   client_max_body_size 72M;\n\n   location ~* ^/(css|dist|js|images|plugins|vendor)/.*\.(css|png|jpg|js|svg|ico|gif|pdf|woff|ttf)$ {}\n\n   location ~* ^/(downloads)/.*\.(pdf|xml|html|csv|zip|rtf)$ {}\n\n   location ~ ^/(ead.dtd|favicon.ico|robots.txt|sitemap.*)$ {}\n\n   location / {\n      try_files $uri /index.php?$args;\n      if (-f $request_filename) {\n         break;\n      }\n   }\n\n   location ~ ^/index\.php($|/) {\n      fastcgi_pass atom;\n      include fastcgi_params;\n      fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;\n      fastcgi_param HTTPS off;\n      fastcgi_buffers 16 16k;\n      fastcgi_buffer_size 32k;\n      fastcgi_read_timeout 600;\n   }\n}" > /etc/nginx/sites-available/atom && \
    ln -sf /etc/nginx/sites-available/atom /etc/nginx/sites-enabled/atom && \
    service nginx restart

# Configurações do Elasticsearch
RUN systemctl enable elasticsearch && \
    systemctl start elasticsearch

# Permissões
RUN chown -R www-data:www-data /usr/share/nginx/atom && \
    chmod o= /usr/share/nginx/atom

# Expor porta do Nginx
EXPOSE 80

# Comando para iniciar serviços
CMD service mysql start && \
    service php7.4-fpm start && \
    service nginx start && \
    tail -f /dev/null
