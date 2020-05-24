#!/usr/bin/env bash

export REPLACE_OS_VARS=true

printf "==> checking environment variables\n"

if [ -f "$RELEASE_ROOT_DIR/dioprc" ]; then
  printf "Sourcing dioprc...\n"
  source "$RELEASE_ROOT_DIR/dioprc"
else
  printf "dioprc not found :(\n"
  exit 1
fi

if [ -z "$NODE_NAME" ]; then
        printf '$NODE_NAME is not set... exiting.\n'
        exit 1
else
        printf "Node name -> ${NODE_NAME}\n"
fi

if [ -z "$NODE_COOKIE" ]; then
        printf '$NODE_COOKIE is not set... exiting.\n'
        exit 1
else
        printf "Node cookie is set\n"
fi

if [ -z "$IMAP_USERNAME" ]; then
        printf '$IMAP_USERNAME is not set... exiting.\n'
        exit 1
else
        printf "IMAP username is set\n"
fi

if [ -z "$IMAP_PASSWORD" ]; then
        printf '$IMAP_PASSWORD is not set... exiting.\n'
        exit 1
else
        printf "IMAP password is set\n"
fi
