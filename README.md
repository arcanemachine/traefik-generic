# traefik-generic

A generic Traefik container setup. Designed to be reasonably secure out of the box, while being easily pluggable for both `dev` and `prod` environments.

## Features

- Easy setup with the automated setup wizard (located at `./setup`).
- Works with Docker and Podman.
  - Works with Docker by default, but can be configured to work with Podman instead.
- Supports Let's Encrypt certificates (when using the `prod` configuration)
  - Traefik automatically manages certificate renewal when using Let's Encrypt. :)

## Usage Instructions

### Configuration

There are 2 ways to configure this project:

- Using the automated setup wizard
- Manual configuration

#### Using the Automated Setup Wizard

##### Quick Start

- Run the automated script located in `./scripts/setup` and follow the steps in the setup wizard.
- Then, run the `./start.sh` script to start the container service.
- To overwrite an existing configuration, use the `--force` flag when running the script.
- To use with Podman, set `USE_PODMAN=1` before running the script (e.g. `USE_PODMAN=1 ./setup`)

##### What Does the Setup Wizard Do?

The wizard performs the following steps:

- Configures the environment:
  - Sets up the following environment variables:
    - `TRAEFIK_HOST`: The hostname that identifies your Traefik dashboard
      - default: `localhost`
    - `LETS_ENCRYPT_EMAIL`: Your email address (used to receive important emails from Let's Encrypt)
      - This variable is only configured in 'prod' mode. It is used to setup the `./etc/traefik.yml` file. It is not saved after running the setup script.
      - default: `letsencrypt@example.com`
    - `DOCKER_HOST`: The path to your Docker/Podman socket.
      - This variable is only configured if the environment variable `USE_PODMAN=1` is enabled before running the setup wizard.
      - default: N/A

##### What Files Does The Setup Wizard Create?

The wizard generates 3 files:

- `./.env` - The local environment (automatically detected by the Compose file)
- `./etc/traefik.yml` - Traefik configuration file
- `./start.sh` - A script that starts the container service

##### How To Use Podman Instead of Docker?

- Use `pip` (The Python package installer) to install `docker-compose` in order for Podman to work with Compose files.
- Run `USE_PODMAN=1 ./setup`
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
- Set up your environment in `./.env`:
  - Supported environment variables:
    - `TRAEFIK_HOST`: The hostname that identifies your Traefik dashboard
      - example: `TRAEFIK_HOST="localhost"`
    - `DOCKER_HOST`: The path to your Podman socket. (Not required if using Docker)
      - example: `DOCKER_HOST="/var/run/docker.sock"`
        - If not set, the `compose.yaml` file will assume the socket is located in `/var/run/docker.sock`
          - This is the standard location of the Docker socket file.
  - A sample config can be created by running `./templates/dotenv.GENERATOR --default`
    - The output of this command can be piped to `.env`
- Set up your Traefik configuration in `./etc/traefik.yml`
  - A sample config can be created by running `./templates/traefik.yml.GENERATOR`
    - You must specify `dev` or `prod` as the first positional argument.
    - The output of this command can be piped to `./etc/traefik.yml`.
- Start the containers with the desired environment:
  - e.g. for Docker: `docker compose -f compose.yaml -f compose.[dev|prod].yaml up`
  - e.g. for Podman: `docker-compose -H unix:/$(podman info --format '{{.Host.RemoteSocket.Path}}') -f compose.yaml -f compose.[dev|prod].yaml up`

### Differences Between 'dev' and 'prod' Configuration

By default, the 'dev' configuration:

- Does not require authentication to view the dashboard
- Does not expose port 443 (HTTPS)
- Does not enable SSL certificates via Let's Encrypt

By default, the 'prod' configuration:

- Requires authentication to view the dashboard
- Exposes port 443 (HTTPS)
- Enables SSL certificates via Let's Encrypt

### Accessing the Traefik Dashboard

By default, the dashboard is accessible from `http://monitor.$TRAEFIK_HOST/`.

- e.g. `http://monitor.localhost/`

The location of the dashboard can be changed by editing the `compose.*.yaml` file for your environment.

### Securing the Dashboard

#### In 'dev' Mode

In 'dev' mode, the dashboard is unsecured by default.

- To enable basic authentication, uncomment lines 25 and 41 in the `compose.dev.yaml` files.
  - The default credentials are `admin` and `password`.
    - The password is hashed. To change the default password, you will need to [generate a new password hash](#set-custom-authentication-credentials).
  - Make sure you change the credentials (or disable the dashboard in `./etc/traefik.yml`) if this service will be accessible from the Internet!

#### In 'prod' Mode

In 'prod' mode, the dashboard is secured with the default username `admin` and a randomly-generated password.

- In order to access the dashboard, you will need to change the password (or disable authentication entirely... which you shouldn't do).

  - To change the password, you will need to [generate a new password hash](#set-custom-authentication-credentials)

#### Set Custom Authentication Credentials

- Ensure that the 'auth' middleware is enabled for your dashboard's router.
  - This is done in the `traefik` -> `services` -> `labels` section of your production-specific compose file (i.e. `compose.dev.yaml` or `compose.prod.yaml`).
    - Example: `- traefik.http.routers.traefik.middlewares=auth`
- Create a hash of your password (a plaintext password will not work!):
  - Use the interactive shell command:
    - Example `mkpasswd --method=bcrypt`
  - Make sure you
    - The password will not work unless it is hashed.
    - Also, it is insecure to store a plaintext password in your repo.
- Add your authentication credentials your production-specific compose file (i.e. `compose.dev.yaml` or `compose.prod.yaml`):
  - The label will contain a username (e.g. `your_username`) and the hashed password you just generated in the previous step.
  - The label should be placed in the `traefik` -> `services` -> `labels` section of your production-specific compose file.
    - e.g. `- "traefik.http.middlewares.auth.basicauth.users=your_username:$$2b$$05$$v2kiZzxQVEouDNeILmzUTeJBE2ScPBJgfKagbLQSDD3fqJtg6.6VW"`
  - Note that the hash contains dollar sign symbols (`$`).
    - YAML uses the `$` symbol as an escape character.
    - For this reason, you must convert each `$` to `$$` (2 dollar sign symbols instead of 1) when copying your hashed password into the YAML config.

### Start the Container Service

#### The Easy Way

If you used the setup wizard, a `./start.sh` script was generated. You can use this script to start the container service.

#### The Manual Way

In 'dev' mode:

- docker: `docker compose -f docker-compose.yaml -f docker-compose.dev.yml up`
- podman: `docker-compose -H "unix:$(podman info --format '{{.Host.RemoteSocket.Path}}')" -f compose.yaml -f compose.dev.yaml up`

In 'prod' mode:

- docker: `docker-compose -f docker-compose.yml -f docker-compose.prod.yml up`
- podman: `docker-compose -H "unix:$(podman info --format '{{.Host.RemoteSocket.Path}}')" -f compose.yaml -f compose.prod.yaml up`

## Troubleshooting

#### I can't access ports below 1024 when using a rootless container.

To allow ports 80-1023 for a non-root user, try running the following command:

- `sudo sysctl net.ipv4.ip_unprivileged_port_start=80`
