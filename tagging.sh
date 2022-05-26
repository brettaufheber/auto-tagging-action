#!/bin/bash

set -euo pipefail

if [[ -z "${COMMAND:-}" ]]; then

  echo "Expect a command to get the version string" >&2
  exit 1

fi

if [[ -z "${SNAPSHOT_PATTERN:-}" ]]; then

  SNAPSHOT_PATTERN='-SNAPSHOT$'

fi

VERSION="$(eval $COMMAND)"

if ! [[ "$VERSION" =~ ^(0|[1-9][0-9]*)(\.(0|[1-9][0-9]*))?(\.(0|[1-9][0-9]*))?(.+)?$ ]]; then

  echo "Cannot process unexpected format for version $VERSION" >&2
  exit 1

fi

echo "Use version $VERSION to process auto-tagging"

echo "::set-output name=version-given::$VERSION"

MAJOR=${BASH_REMATCH[1]}
MINOR=${BASH_REMATCH[3]}
PATCH=${BASH_REMATCH[5]}
SUFFIX=${BASH_REMATCH[6]}

if [[ -n "${MINOR:-}" ]] && [[ -n "${PATCH:-}" ]]; then

  VERSION_WITHOUT_SUFFIX="$MAJOR.$MINOR.$PATCH"

  echo "::set-output name=version-major-minor-patch::$MAJOR.$MINOR.$PATCH"
  echo "::set-output name=version-major-minor::$MAJOR.$MINOR"

elif [[ -n "${MINOR:-}" ]]; then

  VERSION_WITHOUT_SUFFIX="$MAJOR.$MINOR"

  echo "::set-output name=version-major-minor::$MAJOR.$MINOR"

else

  VERSION_WITHOUT_SUFFIX="$MAJOR"

fi

echo "::set-output name=version-major::$MAJOR"
echo "::set-output name=version-without-suffix::$VERSION_WITHOUT_SUFFIX"

if [[ -n "${SUFFIX:-}" ]]; then

  echo "::set-output name=version-suffix::$SUFFIX"

fi

if [[ "$VERSION" =~ $SNAPSHOT_PATTERN ]]; then

  echo "Skip creating tag for version $VERSION (does match snapshot pattern $SNAPSHOT_PATTERN)" >&2

  echo "::set-output name=strategy::snapshot"
  echo "::set-output name=tag-created::no"

else

  if [[ "${KEEP_SUFFIX:-}" == 'yes' ]]; then

    TAG="${TAG_PREFIX:-}$VERSION_WITHOUT_SUFFIX$SUFFIX"

  else

    TAG="${TAG_PREFIX:-}$VERSION_WITHOUT_SUFFIX"

  fi

  echo "::set-output name=version-tag::$TAG"
  echo "::set-output name=strategy::release"

  if [[ -n "$(git tag -l "$TAG")" ]]; then

    echo "Skip creating tag $TAG for version $VERSION (already exists)" >&2

    echo "::set-output name=tag-created::no"

  elif [[ "${DRY_RUN:-}" == 'yes' ]]; then

    echo "Skip creating tag $TAG for version $VERSION (dry run)" >&2

    echo "::set-output name=tag-created::no"

  else

    echo "Create tag $TAG for version $VERSION"

    git tag -a -m "Release version $VERSION" "$TAG"

    if ! [[ "${SKIP_PUSH:-}" == 'yes' ]]; then

      git push origin "$TAG"

    fi

    echo "::set-output name=tag-created::yes"

  fi

fi

if [[ -n "${SUFFIX:-}" ]]; then

  echo "::set-output name=version-suffix::$SUFFIX"

fi

ANNOTATED_TAG_COUNT="$(git tag --list --format="%(refname:short) ^ %(type)" | sed '/commit$/!d' | wc -l)"
HEAD_HASH="$(git rev-parse --verify --short=12 HEAD)"
ALTERNATIVE_SUFFIX="-latest.$ANNOTATED_TAG_COUNT.$HEAD_HASH"

echo "::set-output name=version-alternative::$VERSION_WITHOUT_SUFFIX$ALTERNATIVE_SUFFIX"
echo "::set-output name=version-alternative-suffix::$ALTERNATIVE_SUFFIX"

exit 0
