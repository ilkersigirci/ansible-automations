# Homeserver Docker Compose

Use the native homeserver Docker Compose playbook and pass the Compose action
with `task`.

```bash
uv run ansible-playbook playbooks/homeserver/docker_compose.yml -e task=up
uv run ansible-playbook playbooks/homeserver/docker_compose.yml -e task=update
uv run ansible-playbook playbooks/homeserver/docker_compose.yml -e task=pull
uv run ansible-playbook playbooks/homeserver/docker_compose.yml -e task=prune
uv run ansible-playbook playbooks/homeserver/docker_compose.yml -e task=restart
uv run ansible-playbook playbooks/homeserver/docker_compose.yml -e task=down
```

Actions:

- `up`: start the Compose stack.
- `update`: pull images and start or reconcile the Compose stack. It does not
  prune dangling images.
- `pull`: pull images only.
- `prune`: remove dangling images. This action is skipped in Ansible check mode.
- `restart`: stop and start the Compose stack.
- `down`: stop the Compose stack and remove orphans.

The `prune` action does not require the Compose repository or `.env` file. It
requires the `python3-requests` dependency provisioned by the `docker_install`
role.

## Update Workflow

This playbook only performs Docker operations against the repository and `.env`
already present on each host. It does not update Git or synchronize secrets.

To operate on the latest repository and environment state, run these playbooks
in order:

```bash
uv run ansible-playbook playbooks/homeserver/pull_repo.yml \
  --limit localhost,gpu

uv run ansible-playbook playbooks/homeserver/sync_env.yml \
  --limit localhost,gpu

uv run ansible-playbook playbooks/homeserver/docker_compose.yml \
  -e task=update \
  --limit gpu
```

Limit to one host when needed:

```bash
uv run ansible-playbook playbooks/homeserver/docker_compose.yml \
  -e task=update \
  --limit gpu
```

Exclude a host by combining the target group with an exclusion pattern. The
generic form is `--limit 'group:!host_to_exclude'`. Quote the pattern so the
shell does not interpret `!`:

```bash
uv run ansible-playbook playbooks/homeserver/docker_compose.yml \
  -e task=update \
  --limit 'homeserver:!remoteserver2'
```
