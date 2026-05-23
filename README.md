# README

Dumarket is a basic e-commerce app that is, well, kinda dummy.

## Docker
```bash
# local
docker compose up

# deploy
# 1. (One Time) create the docker context first and init swarm
docker context create <context name for remote vps> --docker "host=ssh://<user>@<vps ip>"
docker --context <context name for remote vps> swarm init

# 2. create some secrets
docker --context <context name for remote vps> secret create db_password <path to file that contains database password>
docker --context <context name for remote vps> secret create rails_master_key config/master.key

# 3. build and push image (it's recommended to build it in local)
docker context use default
docker compose -f compose.yaml -f compose.deploy.yaml build web
docker compose -f compose.yaml -f compose.deploy.yaml push web

# 4. deploy using docker stack
# docker swarm and docker compose has a weird compatibility
docker compose -f compose.yaml -f compose.deploy.yaml config \
  | sed 's/published: "\([0-9]*\)"/published: \1/g' \
  | grep -v "^name:" \
  | docker --context <context name for remote vps> stack deploy -c - dumarket
```
