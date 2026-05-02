# Architecture

This document follows the lightweight codemap style from
[matklad's ARCHITECTURE.md](https://matklad.github.io/2021/02/06/ARCHITECTURE.md.html):
short, stable, and focused on where things live.

## Bird's Eye View

This repository is an Ansible control repo for personal infrastructure. It runs
from a local control node and manages Debian-family targets across local network
hosts, Raspberry Pis, LXCs, and Tailscale-reachable homeserver machines.

The managed application stack is intentionally outside this repo. The
`homeserver-docker` repository owns Docker Compose files and service scripts.
This repo prepares hosts, pulls that repository, writes its `.env` file, and
invokes its `scripts/docker-manage.sh` entry point.

There is no long-running application here. `pyproject.toml` and `uv.lock` pin
the automation toolchain: Ansible, Ansible linting, and pre-commit support.

## Codemap

`ansible.cfg` defines the default inventory, role lookup path, host key policy,
and SSH agent forwarding.

`inventory/hosts.yaml` is the host topology. The main groups are `dev_devices`,
`lxcs`, `rpis`, and `homeserver`.

`inventory/group_vars` holds shared data. `all.yml` defines the default managed
user, SSH public key, and default `ansible_user`. `lxcs.yml` switches LXC setup
to root. `homeserver.yml` defines the external homeserver Docker repository and
remote checkout path.

`inventory/host_vars` holds host-specific overrides. Most homeserver host files
define `env_vars_mapping`, which maps environment variable names to `rbw` items
and fields. Some hosts also override `ansible_user`.

`playbooks/setup_debian.yml` bootstraps Debian LXCs and Raspberry Pis with the
`common` and `docker_install` roles.

`playbooks/apt_update_reboot.yml` runs apt maintenance through `apt_update` and
reboots hosts when `/var/run/reboot-required` exists.

`playbooks/font.yml` installs selected Nerd Fonts on `dev_devices`.

`playbooks/rbw.yml` is a local `rbw` demonstration and smoke test. The production
homeserver secret flow is `playbooks/homeserver/sync_env.yml`.

`playbooks/homeserver/setup_repo.yml` prepares the external homeserver Docker
checkout on every `homeserver` host.

`playbooks/homeserver/sync_env.yml` checks that `rbw` is available locally, then
uses `homeserver_rbw_env` to render a remote `.env` file.

`playbooks/homeserver/docker_manage.yml` checks local `rbw` availability, then
runs `homeserver_docker_manage` as the managed homeserver user.

`roles/common` creates the managed user, installs the SSH key, runs apt
maintenance, installs baseline packages, enables locales, and writes
`MY_HOSTNAME` to `/etc/environment`.

`roles/apt_update` is the reusable apt update, dist-upgrade, autoclean, and
autoremove sequence.

`roles/docker_install` installs Docker CE from Docker's deb822 apt repository,
writes daemon options, adds the managed user to the `docker` group, and ensures
the Docker service is running.

`roles/git_pull` clones or updates the external homeserver Docker repository at
`repo_path` from `repo_url`.

`roles/check_rbw` fails early when the control node cannot run `rbw unlocked`.

`roles/homeserver_rbw_env` merges default and host-specific secret mappings,
delegates `rbw get` calls to localhost, escapes dollar signs for Docker Compose,
and writes the remote `.env` file with mode `0600`.

`roles/homeserver_docker_manage` validates `homeserver_docker_manage_action`,
optionally pulls the external repo, verifies `docker-manage.sh`, and runs it
from `repo_path`.

`roles/nerd_fonts` downloads selected Nerd Font files and refreshes the font
cache when installation changes.

`collections/requirements.yaml` declares Ansible Galaxy collections. Currently
the repo needs `ansible.posix` for authorized keys.

## Main Flows

Bootstrap flow:

1. Pick hosts from `lxcs` or `rpis`.
2. Apply `common` for users, SSH, packages, locales, and hostname environment.
3. Apply `docker_install` for Docker Engine and daemon configuration.

Homeserver repository flow:

1. Use the `homeserver` group and its `repo_url` and `repo_path` values.
2. Run `git_pull` to clone or update the external Docker repository.
3. Keep Compose/service logic in that external repository.

Homeserver secret flow:

1. Validate that `rbw` is unlocked on the control node.
2. Combine default secret mappings with each host's `env_vars_mapping`.
3. Fetch secrets locally, never on the remote host.
4. Write the generated `.env` file to the remote `repo_path`.

Homeserver Docker action flow:

1. Choose an action from `homeserver_docker_manage_actions`.
2. Pull the external repository when the action says it should.
3. Run `scripts/docker-manage.sh` as the managed user with `MY_HOSTNAME` set.

## Architectural Invariants

Inventory is the source of truth for host topology, host addresses, usernames,
static IPs, repo paths, and per-host secret mappings. Avoid hardcoded host data
inside roles.

Playbooks choose hosts and compose roles. Roles should remain reusable units of
behavior and should not assume a single host unless their name says so.

Resolved secrets must stay out of git. Secret values should be fetched from
`rbw` on the control node, hidden with `no_log` where practical, and written only
to their remote destination.

The Docker Compose application architecture belongs to the external
`homeserver-docker` repository. This repo should call that boundary instead of
duplicating service definitions.

Ansible tasks should use fully qualified module names and stay idempotent where
the underlying operation allows it. When a command cannot be naturally
idempotent, define `changed_when` deliberately.

Agent-facing guidance belongs in `docs/`; `AGENTS.md` should remain a short
index to those docs.

## Cross-Cutting Concerns

Tooling is driven through `uv`. Prefer `uv run ansible...`, `uv run
ansible-playbook...`, and `uv run pre-commit...` so the pinned environment is
used consistently.

SSH agent forwarding is part of normal operation because private git access can
be needed from managed hosts.

Validation happens through Ansible syntax checks, pre-commit hooks, and
ansible-lint. For risky host changes, also use `--check`, `--diff`, and
`--limit`.

Remote state is intentionally small: managed users, installed packages, Docker
configuration, checked-out external repositories, and generated `.env` files.

## Where To Change Things

Add or remove a host in `inventory/hosts.yaml`, then add shared values in
`inventory/group_vars` or host-specific values in `inventory/host_vars`.

Change default users, SSH keys, or baseline packages in `roles/common` and
`inventory/group_vars/all.yml`.

Change Docker installation behavior in `roles/docker_install`.

Add a shared homeserver environment variable mapping in
`roles/homeserver_rbw_env/defaults/main.yml`. Add host-specific mappings in the
matching file under `inventory/host_vars`.

Add or tune a Docker management action in `roles/homeserver_docker_manage`.

Add a new workflow as a playbook under `playbooks/`. If the behavior will be
reused, put it behind a role under `roles/`.

Update agent navigation by adding or changing docs under `docs/`, then link them
from `AGENTS.md`.
