*This project has been created as part of the 42 curriculum by ssukhija.*

# Inception

## Description

**Inception** is a system administration and containerization project that builds a multi-service web infrastructure from scratch using **Docker** and **Docker compose** inside a dedicated Virtual Machine. Rather than pulling pre-built application images from Docker Hub, every service is compiled from a custom `Dockerfile` based on `debian:bookworm` and orchestrated through a root `Makefile`.

The stack deploys three isolated services connected over an internal bridge network (`inceptNet`):

* ** NGINX:** Acts as the sole external entry point on port `443`, terminating HTTPS traffic with a self-signed TLSv1.2/TLSv1.3 certificate and proxying PHP requests over FastCGI to WordPress.
* **WordPress (PHP-FPM 8.2):** Runs the WordPress CMS and communicates with MariaDB on internal port `3306` and NGINX on internal port `9000`.
* **MariaDB:** Provides the relational database backend storing all site content, users, and configuration.

For step-by-step operational guides, see [`USER_DOC.md](USER_DOC.md) and [`DEV_DOC.md`](DEV_DOC.md).

---

## Project Architecture & Design Choices

### 1. Virtual Machines Vs. Docker

| Aspect | Virtual Machines (VMs) | Docker Containers |
| :--- | :--- | :--- |
| **Isolation Level** | Hardware-level virtualization via a hypervisor; each VM runs a full guest OS and kernel. | OS-level process isolation sharing the host Linux kernel via namespaces and cgroups. |
| **Resource Overhead** | Heavy RAM and disk footprint (gigabytes per VM) with slower boot times. | Lightweight image layers (megabytes) starting in milliseconds. |
| **Use in Inception** | Provides the isolated host Linux environment required by the 42 subject. | Separates NGINX, WordPress, and MariaDB into single-responsibility processes (`PID 1`). |

### 2. Secrets vs. Environment Variables

|Aspect | Enviornment Variables (`src/.env`) | Docker Secrets (`secrets/`) |
| :--- | :--- | :--- |
| **Visibility** | Visible via `docker inspect`, process environments, and child processes. | Mounted read-only in memory at `/run/secrets/` only for authorized containers. | 
**Use in Inception** | Stores non-sensitive configuration (`DOMAIN_NAME`, `MYSQL_DATABASE`, `MYSQL_USER`, `WP_TITLE`, `WP_ADMIN_USER`, `WP_USER`). | Protects sensitive credentials (`db_root_password.txt`, `db_password.txt`, `wp_creds.txt`) from leaking into image layers or logs. |

### 3. Docker Network vs. Host Network

| Aspect | Host Network (`network_mode: host`) | Custom Docker Bridge (`inceptNet`) |
| :--- | :--- | :--- |
| **Port & Interface Isolation** | Shares the host's network stack directly; any bound port is immediately exposed on the VM. | Creates an isolated virtual network with embedded DNS resolution (`mariadb`, `wordpress`, `nginx`). |
| **Security & Control** | No network-level segmentation between services or external interfaces. | Keeps MariaDB (`3306`) and PHP-FPM (`9000`) strictly internal while exposing only NGINX port `443` to the host. |

### 4. Docker Volumes vs. Bind Mounts

| Aspect | Standard Anonymous/Named Volumes | Host-Backed Bind Mounts (`/home/ssukhija/data/`) |
| :--- | :--- | :--- |
| **Storage Location** | Managed internally by Docker inside `/var/lib/docker/volumes/`. | Mapped directly to explicit directories on the host filesystem (`/home/ssukhija/data/mariadb` and `/home/ssukhija/data/wordpress`). |
| **Evaluation & Persistence** | Harder to inspect directly on the host without `docker volume inspect`. | Satisfies the 42 requirement that persistent data resides in `/home/<login>/data/` and survives container removal and VM reboots. |

---

## Instructions

### Prerequisites
* Linux Virtual Machine with **Docker Engine**, **Docker Compose v2**, **GNU Make**, and **OpenSSL** installed.
* Local domain resolution configured in `/etc/hosts`:
```bash
echo "127.0.0.1 ssuhkija.42.fr" | sudo tee -a /etc/hosts
```

### Configuration
Create `srcs/.env` and the `secrets/` directory at the repository root (both are excluded via `.gitignore`):

1. **`srcs.env`:**
```env
DOMAIN_NAME=ssukhija.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
WP_TITLE=Inception
WP_ADMIN_USER=sarb
WP_ADMIN_EMAIL=sarb@student.42.fr
WP_USER=author_user
WP_USER_EMAIL=author@student.42.fr
```

2. **`secrets/ directory:**
```bash
mkdir -p secrets
echo "RootPassword" > secrets/db_root_password.txt
echo "UserPassword" > secrets/db_password.txt
cat << 'EOF' > secrets/wp_creds.txt
WP_ADMIN_PASSWORD=
WP_USER_PASSWORD=
EOF
```

### Build and Run
Execute the following commands from the root of the repository (`~/inception`):

* **Build images and start all containers:**
```bash
make
```
* **Check runnings containers and port mappings:**
```bash
make ps
```
* **Stop containers without deleting persistent data:**
```bash
docker compose -f srcs/docker-compose.yml down
```
* **Access the site:** Open `https://ssukhija.42.fr` (or `https:ssukhija.42.fr/wp-admin`) in a browser and accept the self-signed TLS certificate warning.

---

## Resources

### Technical Documentation
* [Docker Official Documentation - Dockerfile & Compose Reference](https://docs.docker.com/)
* [NGINX Documentation - Configuration & Authentication](https://nginx.org/en/docs/)
* [MariaDB Knowledge Base - Server Configuration & Authentication](https://mariadb.com/kb/en/)
* [WP-CLI Command Reference](https://developer.wordpress.org/cli/commands/)
* [OpenSSL Documentation - Generating Self-Signed X.509 Certificates](https://docs.openssl.org/)

### Use of AI
AI assisatance was used during development as a technical reference and debugging aid for:
* Diagnosing POSIX /`bin/sh` syntax issues in `entrypoint.sh` scripts, `CRLF` line-ending pitfalls in secret files, and FastCGI routing headers (`HTTPS on` and `HTTP_HOST`) between NGINX and PHP-FPM.
* Reviewing `Dockerfile`, `docker-compose.yml`, and `nginx.conf` configurations against the 42 Inception evaluation rubric (PID 1 signal handling, TLSv1.2/1.3 enforcement, and non-root/secrets hygiene).
* Structuring and proofreading `README.md`, `USER_DOC.md`, and `DEV_DOC.md` to ensure clear operational and architectural doumentation.

