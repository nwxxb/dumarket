# README

# Docker

We are currently use docker's compose feature for both development and production
```
# local
# 1. please copy the .env and fill it first
# 2. please create secrets file listed in compose.yaml
# 3. then you can run
docker compose up

# deployment (you can use COMPOSE_FILE env variable)
# 4. please change the .env file to the correct context
# 5. you need to prepare the proper secrets dir listed in compose-deploy.yaml
COMPOSE_FILE=compose.yaml:compose-deploy.yaml docker compose up
```
