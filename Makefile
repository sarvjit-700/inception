
NAME = inception
COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = $(HOME)/data

all: up

up: 
	@mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	docker compose -f $(COMPOSE_FILE) up -d --build

down: 
	docker compose -f $(COMPOSE_FILE) down

stop: 
	docker compose -f $(COMPOSE_FILE) stop

clean: down
	docker system prune -af

fclean: down
	docker system prune -af --volumes
	sudo rm -rf $(DATA_DIR)/mariadb/* $(DATA_DIR)/wordpress/*

re: fclean all

logs:
	docker compose -f $(COMPOSE_FILE) logs -f

ps:
	docker compose -f $(COMPOSE_FILE) ps

nginx:
	docker compose -f $(COMPOSE_FILE) up -d --build nginx

.PHONY: all up down stop start clean fclean re logs ps  nginx