# Developer Documentation

## 1. Environment Setup from Scratch

### System Prerequisites
The host virtual machine requires the following packages installed and running:
* **Docker Engine** and **Docker Compose v2** (`docker compose`)
* **GNU Make** (`make`)
* **Git** and **OpenSSL**

### Host Domain Resolution
Map the project domain to localhost in `etc/hosts` so browser and `curl` requests resolve locally:
```bash
echo "127.0.0.1 ssukhija.42.fr" | sudo tee -a /etc/hosts
```

### Repository Structure
```text
~/inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                          # Ignored by Git
│   ├── db_root_password.txt
│   ├── db_password.txt
│   └── wp_creds.txt
└── srcs/
    ├── .env                          # Ignored by Git
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── .dockerignore
        │   ├── Dockerfile
        │   ├── conf/50-server.cnf
        │   └── tools/entrypoint.sh
        ├── nginx/
        │   ├── .dockerignore
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/entrypoint.sh
        └── wordpress/
            ├── .dockerignore
            ├── Dockerfile
            ├── conf/www.conf
            └── tools/entrypoint.sh
```

---
## 2. Building and Launching the Project

All orchestration is handled through the root 'Makefile' and srcs/docker-compose.yml':

* **Build images and start all containers:**
```bash
make
```
This creates `/home/ssukhija/data/mariadb` and `/home/ssukhija/data/wordpress` on the host, builds each custom image from `debian:bookworm`, creates the `inceptNet` bridge network, and starts `mariadb`, `wordpress`, and `nginx` in detached mode with `restart: always`.

* **Rebuild a single service after modifying its 'Dockerfile', config, or 'entrypoint.sh':**
```bash
docker compose -f srcs/docker-compose.yml up -d --build <service_name>
```

---

## 3. Managing Containers, Volumes, and Networks

### Container Operations
* **Check container status and exposed ports:**
```bash
make ps         # or docker compose -f srcs/docker-compose.yml ps
```
* **View real-time logs for all services or one specific container:**
```bash
docker compose -f srcs/docker-compose.yml logs -f
docker compose -f srcs/docker-compose.yml logs -f wordpress
```

* **Open an interesection shell inside a running container:**
```bash
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash
```
* **Query MariaDB directly:**
```bash
docker exec -it mariadb mariadb -uroot -p"$(cat secrets/db_root_password.txt)"
USE wordpress;
```
* **Run WP-CLI commands inside WordPress:**
```bash
docker exec -it wordpress wp user list --allow-root
```

### Network Inspection
All three containers communicate exclusively over the custom `incepNet` bridge network using Docker's embedded DNS (resolving `mariadb:3306` and `wordpress:9000` by service name). Only `nginx` publishes port `443` to the host.
```bash
docker network ls
docker network inspect srcs_inceptNet
```

### Volume Inspection & Reset
* **List Docker volumes:**
```bash
docker volume ls
```
* **Full clean reset (wipes containers, images, volumes, and presistent host data):**
```bash
docker compose -f srcs/docker-compose.yml down -v
sudo rm -rf /home/ssukhija/data/mariadb/* /home/ssukhija/data/wordpress/*
```

---

## 4. Data Persistence & Security Architecture

### Host Bind Mounts
Persistent data is stored on the host filesystem via Docker named volumes configured with local `bind` driver options in `srcs/docker-compose.yml`:
* **`marinadb data`:** Maps `/home/ssukhija/data/mariadb` (host) to `/var/lib/mysql` (container).
* **`wordpress data`:** Maps `/home/ssukhija/data/wordpress` (host) to `/var/www/html` (container), shared read-write with `wordpress` (PHP-FPM) and `nginx` (for static assets).

### Idempotent Startup Scripts
Each service uses a POSIX `/bin/sh` `entrypoint.sh` script that checks whether persistent files already exist before initializing:
* **MariaDB:** Runs `mariadb-install-db` and creates `${MYSQL_DATABASE}` and `${MYSQL_USER}` only when `/var/lib/mysql/${MYSQL_DATABASE}` does not exist.
* **WordPress:** Waits for MariaDB via `maridb-admin ping`, then downloads core files, generates `wp-config.php`, installs WordPress, and creates users only when `/var/www/html/wp-config.php` is absent.
* **NGINX:** Generates a self-signed RSA 2048-bit certificate at `/etc/nginx/ssl/inception.crt` only if the certificate file is missing.

Because existing directories and config files are skipped on subsequent boots, all database records, uploaded media, and user changes survive `docker compose down && make` as well as a full VM `sudo reboot`.

### Runtime Secrets & Process Model
* **Docker Secrets:** Sensitive credentials in `secrets/` are mounted read-only in memory at `/run/secrets/` (`db_root_password`, `db_password`, `wp_creds`) rather than baked into image layers or passed as plain environment variables.
* **PID 1 Execution:** Every `entrypoint.sh` ends with `exec` (`exec mariadb`, `exec php-fpm8.2 -F`, `exec nginx -g "daemon off;"`) so the primary daemon runs in the foreground as PID 1 and receives `SIGTERM` signals cleanly during shutdown.

## Bonus Services Architecture

Two additional containers are built from custom `debian:bookworm` Dockerfiles under `srcs/requirements/bonus/` and attached to the `inceptNet` bridge network:

1. **`adminer` (`srcs/requirements/bonus/adminer/Dockerfile`)**
   * Installs `php` and `php-mysqli`, fetches the standalone Adminer PHP release, and runs PHP's built-in web server in the foreground on port `8080`.
   * Communicates with the `mariadb` container internally over `inceptNet` using the `mariadb` service hostname.
   * Requires no persistent host volume.

2. **`static_site` (`srcs/requirements/bonus/static_site/Dockerfile`)**
   * Copies `index.html` into `/var/www/static` and serves it using `python3 -m http.server 8081 with zero PHP dependencies.
   * Requires no persistent host volume.

### Managing Bonus Services Individually
To rebuild or inspect logs for a single bonus service without restarting the entire stack:
```bash
docker compose -f srcs/docker-compose.yml up --build -d adminer
docker compose -f srcs/docker-compose.yml logs -f static_site