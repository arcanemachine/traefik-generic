# [traefik-generic](https://github.com/arcanemachine/traefik-generic)

A generic Traefik container setup. Designed to be reasonably secure out of the box, while being easily pluggable for both `local` and `remote` environments.

## Features

- Get started with a single command: `./start.sh`
- Works with Docker and Podman.
  - To use with Podman, pass `--podman` as the third positional argument when running `start.sh`.
- Supports Let's Encrypt certificates (when using the `remote` configuration)
  - Traefik automatically manages certificate renewal when using Let's Encrypt.

## Usage Instructions

Before continuing, ensure that `docker-compose` is installed: `pip install docker-compose`

### Configuration

There are 2 ways to configure this project:

- `start.sh`
- Manual configuration

#### Use `start.sh`

##### Quick Start

- Run the `./start.sh up local` script to start the container service with a `local` configuration (no HTTPS).
  - To enable HTTPS, run `./start up remote`
- Access your Traefik dashboard at `http://localhost`.

##### How To Use Podman Instead of Docker?

- Run `start.sh local --podman` or
  - To overwrite an existing config, run `USE_PODMAN=1 ./setup --force`

###### Why Use `docker-compose` Instead of `podman-compose`?

`docker-compose` works better than `podman-compose` in my experience:

- It has a better UI.
- It works better with environment variables than `podman-compose` (at the time of this writing).

If you want to, you can use `podman-compose`, but you'll have to modify the startup command used in `start.sh`.

#### Manual Configuration

All commands should be run from the project root directory.

- Create the `traefix-global-proxy` Docker/Podman network:
  - Docker: `docker network create traefik-global-proxy`
  - Podman: `podman network create traefik-global-proxy`
- Configure your environment variables in `./.env`:
  - Supported environment variables:
    - `TRAEFIK_HOST`: The hostname that identifies your Traefik dashboard
      - example: `TRAEFIK_HOST="localhost"`
    - `DOCKER_HOST`: The path to your Podman socket. (Not required if using Docker)
      - example: `DOCKER_HOST="/var/run/user/1000/podman/podman.sock"`
        - If not set, the `compose.yaml` file will assume the socket is located in `/var/run/docker.sock`
          - This is the standard location of the Docker socket file.
  - A sample config can be created by running `./dotenv-generate.sh`.
- Set up your Traefik configuration:
  - `local` configuration: `./etc/local/traefik.yml`
  - `remote` configuration: `./etc/remote/traefik.yml`
- Start the containers with the desired environment:
  - Docker:
    - `local` configuration: `docker compose -f compose.yaml -f compose.config-local.yaml up`
    - `remote` configuration: `docker compose -f compose.yaml -f compose.config-remote.yaml up`
  - Podman:
    - `local` configuration: `docker-compose -H unix:$(podman info --format '{{.Host.RemoteSocket.Path}}') -f compose.yaml -f compose.config-local.yaml up`
    - `remote` configuration: `docker-compose -H unix:$(podman info --format '{{.Host.RemoteSocket.Path}}') -f compose.yaml -f compose.config-remote.yaml up`

### Differences Between `local` and `remote` Configuration

#### Local

The default local configuration should be used in an environment which is not exposed directly to the Internet (ie. during development).

By default, the `local` configuration:

- Does not require authentication to view the dashboard
- Only exposes port 80 (HTTP)
- Does not enable SSL certificates via Let's Encrypt

#### Remote

The remote configuration should be used in an environment which is exposed directly to the Internet (ie. in production).

By default, the `remote` configuration:

- Requires authentication to view the dashboard
- Exposes ports 80 (HTTP) and 443 (HTTPS)
- Enables SSL certificates via Let's Encrypt

### Accessing the Traefik Dashboard

The dashboard is accessible from `http://$TRAEFIK_HOST/`.

- If you did not modify the default `.env` file, the Traefik dashboard will be accessible at `http://localhost/`

### Securing the Dashboard

#### In `local` Mode

In `local` mode, the dashboard is unsecured by default.

- To enable basic authentication, uncomment lines 25 and 41 in the `compose.config-local.yaml` file.
  - The default credentials are `admin` and `password`.
    - The password is hashed. To change the default password, you will need to [generate a new password hash](#set-custom-authentication-credentials).
  - Make sure you change the credentials (or disable the dashboard in `./volumes/etc/traefik.yml`) if this service will be accessible from the Internet!

#### In `remote` Mode

In `remote` mode, the dashboard is secured with the default username `admin` and a randomly-generated password.

- In order to access the dashboard, you will need to change the password (or disable authentication entirely... which you shouldn't do).
  - The password is hashed. To change the default password, you will need to [generate a new password hash](#set-custom-authentication-credentials).

#### Set Custom Authentication Credentials

- Ensure that the 'auth' middleware is enabled for your dashboard's router.
  - This is done in the `traefik` -> `services` -> `labels` section of your environment-specific compose file (i.e. `compose.config-local.yaml` or `compose.config-remote.yaml`).
    - Example: `- traefik.http.routers.traefik.middlewares=auth`
- Create a hash of your password (a plaintext password will not work!):
  - Use the interactive shell command:
    - Example `mkpasswd --method=bcrypt`
  - Make sure you
    - The password will not work unless it is hashed.
    - Also, it is insecure to store a plaintext password in your repo.
- Add your authentication credentials your environment-specific compose file (i.e. `compose.config-local.yaml` or `compose.config-remote.yaml`):
  - The label will contain a username (e.g. `your_username`) and the hashed password you just generated in the previous step.
  - The label should be placed in the `traefik` -> `services` -> `labels` section of your environment-specific compose file.
    - e.g. `- "traefik.http.middlewares.auth.basicauth.users=your_username:$$2b$$05$$v2kiZzxQVEouDNeILmzUTeJBE2ScPBJgfKagbLQSDD3fqJtg6.6VW"`
  - Note that the hash contains dollar sign symbols (`$`).
    - YAML uses the `$` symbol as an escape character.
    - For this reason, you must convert each `$` to `$$` (2 dollar sign symbols instead of 1) when copying your hashed password into the YAML config.

### Start the Container Service

#### The Easy Way

Use the `start.sh` script. This script takes up to 3 positional arguments.

The first positional argument must specify the 'docker-compose' command(s) to run.

- Examples: up, down, restart, etc.

The second positional argument must specify the location of the deployment.

- Must be one of: local, remote
  - local: no HTTPS
  - remote: uses HTTPS

To use Podman instead of Docker, pass the '--podman' flag as the last positional argument.

#### The Manual Way

In `local` mode:

- docker: `docker compose -f compose.yaml -f compose.config-local.yaml up`
- podman: `docker-compose -H "unix:$(podman info --format '{{.Host.RemoteSocket.Path}}')" -f compose.yaml -f compose.config-local.yaml up`

In `remote` mode:

- docker: `docker-compose -f compose.yaml -f compose.remote.yaml up`
- podman: `docker-compose -H "unix:$(podman info --format '{{.Host.RemoteSocket.Path}}')" -f compose.yaml -f compose.config-remote.yaml up`

## Troubleshooting

#### I can't access ports below 1024 when using a rootless container.

To allow ports 80-1023 for a non-root user, try running the following command:

- `sudo sysctl net.ipv4.ip_unprivileged_port_start=80`
