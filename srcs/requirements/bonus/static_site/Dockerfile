FROM debian:bookworm

RUN apt-get update && apt-get update -y && \
    apt-get install -y --no-install-recommends python3 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/static

COPY index.html .

EXPOSE 8081

CMD ["python3", "-m", "http.server", "8081"]