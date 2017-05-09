#!/bin/bash

# this will trap any errors or commands with non-zero exit status
# by calling function catch_errors()
trap catch_errors ERR;

function catch_errors() {
   exit_code=$?
   echo "### FAILURE ###";
   exit $exit_code;
}

# Check whether given command exists and call it with the --version flag.
check_command_exists() {
  if command -v "$1" > /dev/null 2>&1; then
    echo "$1 version: $($1 --version)"
  else
    echo "RADAR-CNS cannot start without $1. Please, install $1 and then try again"
    exit 1
  fi
}

# Check if the parent directory of given variable is set. Usage:
# check_parent_exists MY_PATH_VAR $MY_PATH_VAR
check_parent_exists() {
  if [ -z "$2" ]; then
    echo "Directory variable $1 is not set in .env"
  fi
  PARENT=$(dirname $2)
  if [ ! -d "${PARENT}" ]; then
    echo "RADAR-CNS stores volumes at ${PARENT}. If this folder does not exist, please create the entire path and then try again"
    exit 1
  fi
}

# sudo if on Linux, not on OS X
# useful for docker, which doesn't need sudo on OS X
sudo-linux() {
  if [ $(uname) == "Darwin" ]; then
    "$@"
  else
    sudo "$@"
  fi
}

# OS X/linux portable sed -i
sed_i() {
  if [ $(uname) == "Darwin" ]; then
    sed -i '' "$@"
  else
    sudo sed -i -- "$@"
  fi
}

# Inline variable into a file, keeping indentation.
# Usage:
# inline_variable VARIABLE_SET VALUE FILE
# where VARIABLE_SET is a regex of the pattern currently used in given file to set a variable to a value.
# Example:
# inline_variable 'a=' 123 test.txt
# will replace a line '  a=232 ' with '  a=123'
inline_variable() {
  sed_i 's|^\([[:space:]]*'"$1"'\).*$|\1'"$2"'|' "$3"
}

# Copies the template (defined by the given config file with suffix
# ".template") to intended configuration file, if the file does not
# yet exist.
copy_template_if_absent() {
  if [ ! -e "$1" ]; then
    sudo-linux cp -p "${1}.template" "$1"
  elif [ "$1" -ot "${1}.template" ]; then
    echo "Configuration file ${1} is older than its template ${1}.template."
    echo "Please edit ${1} to ensure it matches the template, remove it or"
    echo "run touch on it."
    exit 1
  fi
}

self_signed_certificate() {
  SERVER_NAME=$1
  SSL_PATH="/etc/openssl/live/${SERVER_NAME}"
  echo "==> Generating self-signed certificate"
  sudo-linux docker run -i --rm -v certs:/etc/openssl -v certs-data:/var/lib/openssl alpine:3.5 \
      /bin/sh -c "mkdir -p '${SSL_PATH}' && touch /var/lib/openssl/.well-known && apk update && apk add openssl && openssl req -x509 -newkey rsa:4086 -subj '/C=XX/ST=XXXX/L=XXXX/O=XXXX/CN=localhost' -keyout '${SSL_PATH}/privkey.pem' -out '${SSL_PATH}/chain.pem' -days 3650 -nodes -sha256 && cp '${SSL_PATH}/chain.pem' '${SSL_PATH}/fullchain.pem' && rm -f '${SSL_PATH}/.letsencrypt'"
}

letsencrypt_certonly() {
  SERVER_NAME=$1
  SSL_PATH="/etc/openssl/live/${SERVER_NAME}"
  echo "==> Requesting Let's Encrypt SSL certificate for ${SERVER_NAME}"

  # start from a clean slate
  sudo-linux docker-compose stop webserver
  sudo-linux docker run --rm -v certs:/etc/openssl alpine:3.5 /bin/sh -c "find /etc/openssl -name '${SERVER_NAME}*' -exec rm -rf '{}' ';'"
  sudo-linux docker-compose start webserver

  CERTBOT_DOCKER_OPTS=(-i --rm -v certs:/etc/letsencrypt -v certs-data:/data/letsencrypt deliverous/certbot)
  CERTBOT_OPTS=(--webroot --webroot-path=/data/letsencrypt -d "${SERVER_NAME}")
  sudo-linux docker run "${CERTBOT_DOCKER_OPTS[@]}" certonly "${CERTBOT_OPTS[@]}"

  # mark the directory as letsencrypt dir
  sudo-linux docker run -i --rm -v certs:/etc/openssl alpine:3.5 /usr/bin/touch "${SSL_PATH}/.letsencrypt"
}

letsencrypt_renew() {
  SERVER_NAME=$1
  echo "==> Renewing Let's Encrypt SSL certificate for ${SERVER_NAME}"
  CERTBOT_DOCKER_OPTS=(-i --rm -v certs:/etc/letsencrypt -v certs-data:/data/letsencrypt deliverous/certbot)
  CERTBOT_OPTS=(--webroot --webroot-path=/data/letsencrypt -d "${SERVER_NAME}")
  sudo-linux docker run "${CERTBOT_DOCKER_OPTS[@]}" certonly "${CERTBOT_OPTS[@]}"
}

init_certificate() {
  SERVER_NAME=$1
  SSL_PATH="/etc/openssl/live/${SERVER_NAME}"
  if sudo-linux docker run --rm -v certs:/etc/openssl alpine:3.5 /bin/sh -c "[ ! -e '${SSL_PATH}/chain.pem' ]"; then
    self_signed_certificate "${SERVER_NAME}"
  fi
}

request_certificate() {
  SERVER_NAME=$1
  SELF_SIGNED=$2
  SSL_PATH="/etc/openssl/live/${SERVER_NAME}"

  init_certificate "${SERVER_NAME}"
  CURRENT_CERT=$(sudo-linux docker run --rm -v certs:/etc/openssl alpine:3.5 /bin/sh -c "[ -e '${SSL_PATH}/.letsencrypt' ] && echo letsencrypt || echo self-signed")

  if [ "${CURRENT_CERT}" = "letsencrypt" ]; then
    if [ "$3" != "force" ]; then
      echo "Let's Encrypt SSL certificate already exists, not renewing"
      return
    fi

    if [ "${SELF_SIGNED}" = "yes" ]; then
      echo "Converting Let's Encrypt SSL certificate to a self-signed SSL"
      self_signed_certificate "${SERVER_NAME}"
    fi
    if [ "$3" = "force"]; then
      letsencrypt_renew "${SERVER_NAME}"
    fi
  else
    if [ "${SELF_SIGNED}" = "yes" ]; then
      if [ "$3" = "force" ]; then
        echo "WARN: Self-signed SSL certificate already existed, recreating"
        self_signed_certificate "${SERVER_NAME}"
      else
        echo "Self-signed SSL certificate exists, not recreating"
        return
      fi
    else
      letsencrypt_certonly "${SERVER_NAME}"
    fi
  fi
  sudo-linux docker-compose kill -s HUP webserver
}

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose
