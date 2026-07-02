# Homeserver Docker Manage

Use the legacy homeserver Docker playbook and pass the script action with
`homeserver_docker_manage_action`.

```bash
uv run ansible-playbook playbooks/homeserver/docker_manage.yml -e homeserver_docker_manage_action=up
uv run ansible-playbook playbooks/homeserver/docker_manage.yml -e homeserver_docker_manage_action=update
uv run ansible-playbook playbooks/homeserver/docker_manage.yml -e homeserver_docker_manage_action=pull
uv run ansible-playbook playbooks/homeserver/docker_manage.yml -e homeserver_docker_manage_action=prune
uv run ansible-playbook playbooks/homeserver/docker_manage.yml -e homeserver_docker_manage_action=restart
uv run ansible-playbook playbooks/homeserver/docker_manage.yml -e homeserver_docker_manage_action=down
```

Actions:

- `up`: run `docker-manage.sh up`.
- `update`: run `docker-manage.sh update`.
- `pull`: run `docker-manage.sh pull`.
- `prune`: run `docker-manage.sh prune`.
- `restart`: run `docker-manage.sh restart`.
- `down`: run `docker-manage.sh down`.

This playbook does not perform Git operations. Run `setup_repo.yml` separately
when the repository checkout must be updated.

Limit to one host when needed:

```bash
uv run ansible-playbook playbooks/homeserver/docker_manage.yml \
  -e homeserver_docker_manage_action=restart \
  --limit gpu
```
