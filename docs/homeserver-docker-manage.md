# Homeserver Docker Manage

Use the generic homeserver Docker playbook and pass the script action with
`homeserver_docker_manage_action`.

```bash
uv run ansible-playbook playbooks/homeserver/docker_manage.yml -e homeserver_docker_manage_action=up
uv run ansible-playbook playbooks/homeserver/docker_manage.yml -e homeserver_docker_manage_action=pull
uv run ansible-playbook playbooks/homeserver/docker_manage.yml -e homeserver_docker_manage_action=restart
uv run ansible-playbook playbooks/homeserver/docker_manage.yml -e homeserver_docker_manage_action=down
```

Actions:

- `up`: pull the latest Git changes, then run `docker-manage.sh up`.
- `pull`: pull the latest Git changes, then run `docker-manage.sh pull`.
- `restart`: run `docker-manage.sh restart`.
- `down`: run `docker-manage.sh down`.

Limit to one host when needed:

```bash
uv run ansible-playbook playbooks/homeserver/docker_manage.yml \
  -e homeserver_docker_manage_action=restart \
  --limit gpu
```
