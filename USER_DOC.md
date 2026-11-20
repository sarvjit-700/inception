# User Documentation

## 1. Overview of Services Provided

This stack hosts a self-contained WordPress website running across three isolated Docker containers:

* **NGINX:** Acts as the sole public entry point on **port 443**, terminating **HTTPS connections with self-signed TLSv1.2/TLSv1.3 certificate and forwarding PHP requests to WordPress.
* **WordPress (with PHP-FPM):** Runs the content management system and processes dynamic PHP pages on internal **port 9000**.
* **MariaDB:** Stores all WordPress posts, pages, comments, users and site settings on internal **port 3306**.

---

## 2. Starting and Stopping the Project

Run all commands from the root of the repository ('~/inception'):

* Build and start all services in the background:**
```bash
make
```
* Stop and remove the running containers and network (preserving the website data):**
```bash
docker compose -f srcs/docker-compose.yml down
```
* Stop services temporarily without removing containers:**
```bash
docker compose -f srcs/dockers-compose.yml stop
```

## 3. Accessing the website and Administration Panel

### Browser URLs :

Public Website: https://ssukhija.42.fr

WordPress Admin Dashboard: http://ssukhija.42.fr/wp-admin

>[Note on TLS Warning]: *Because NGINX uses a self-signed SSL/TLS certificate, the browser will display a security warning on first visit. Click **Advanced** and choose **Accept the Risk and Continue** (Firefox) or **Proceed to ssukhija.42.fr (Chromium/Chrome)**. Plain HTTP (http://ssukhija.42.fr on port 80) is intentionally disabled.*

## 4. Locating and Managing Credentials

All configuration and password files live locally on the host and are excluded from the Git:

* General Configuration ( srcs/.env ): Stores non-sensitive settings including

    DOMAIN_NAME , MYSQL_DATABASE , MYSQL_USER , WP_TITLE , WP_ADMIN_USER , WP_ADMIN_EMAIL , WP_USER and WP_USER_EMAIL .

* Secrets Directory ( secrets/ ): Stores all passwords in plain-text files mounted read-only inside containers at /run/secrets/ :
  
    * secrets/db_root_password.txt - MariaDB password for root **password**.

    * secrets/db_password.txt - **MariaDB password for** wp_user.

    * secrets/wp_creds.txt ** - WordPress administrator (**
      WP_ADMIN_PASSWORD **) and secondary author (**
      WP_USER_PASSWORD **) passwords.**

### Updating Credentials
  * Before initial setup: Edit the values inside secrets/*.txt and srcs/.env before running make .
 
  * On a running site: Update WordPress user passwords directly through the WordPress Dashboard (Users -> Profile) or via WP-CLI:
    ```bash
    docker exec -it wordpress wp option update sarb --user_pass="NewPasswordHere" --allow-root
    ```

## 5. Checking That Services Are Running Properly

1. Verify container status:
   ```bash
   make ps
   ```
   All three containers ( mariadb, wordpress, and nginx ) should display the status Up , with nginx exposing `0.0.0.0.:443->443/tcp`.

2. Inspect container logs:
    ```bash
    docker compose -f srcs/doker-compose.yml logs
    ```
    Confirm mariadb reports ready for connections and wordpress reports ready to handle connections without restart loops.

3. Test HTTPS response from the terminal:
   ```bash
   curl -kI [https://ssukhija.42.fr](https::/ssukhija.42.fr)
   ```
   A healthy stack returns `HTTP/1.1 200 ok`.






   
