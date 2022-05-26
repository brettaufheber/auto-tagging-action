#!/bin/bash

set -euo pipefail

if ! git config user.name; then

  if [[ -z "${GIT_USERNAME:-}" ]]; then

    GIT_USERNAME="$(cat "$GITHUB_EVENT_PATH" | jq -r '.pusher.name')"

  fi

  git config user.name "$GIT_USERNAME"

fi

if ! git config user.email; then

  if [[ -z "${GIT_EMAIL:-}" ]]; then

    GIT_EMAIL="$(cat "$GITHUB_EVENT_PATH" | jq -r '.pusher.email')"

  fi

  git config user.email "$GIT_EMAIL"

fi

git fetch --tags

exit 0
