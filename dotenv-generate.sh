#!/bin/sh

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Generate a .env file template. You can override the default environment
variables as needed.

To generate the default template, pass the '--default' flag as the first
positional argument.

Available environment variable(s):

- TRAEFIK_HOST: The hostname that identifies your Traefik dashboard
  - default: 'localhost'
"
  exit 0
fi

cd "$(dirname "$0")" || exit 1

echo "Creating '.env' file in project root directory..."

# traefik_host
traefik_host="${TRAEFIK_HOST:-}"
if [ "$1" = "--default" ] || [ "$TRAEFIK_HOST" = "" ]; then
  # use default value
  default_traefik_host="localhost"
  echo "Using default TRAEFIK_HOST '$default_traefik_host'...."
  traefik_host="TRAEFIK_HOST=\"localhost\""
else
  echo "Using TRAEFIK_HOST '$TRAEFIK_HOST'...."

  # use custom value
  traefik_host="TRAEFIK_HOST=\"${traefik_host}\""
fi

echo "${traefik_host}" >.env
