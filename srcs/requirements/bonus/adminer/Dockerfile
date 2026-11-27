FROM debian:bookworm

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    php \
    php-mysqli \
    wget \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

RUN wget -q "https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php" -O index.php && \
    chown -R www-data:www-data /var/www/html

EXPOSE 8080

CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]