#!/bin/bash

VERSION="$1"
NO_OPT="$2"

if [[ -z $VERSION ]]; then
  echo "USAGE: $0 <version> [--no-tag|--no-checkout]"
  echo " e.g.: $0 0.1.0"
  exit 1
fi

function fail {
  local msg="$1"
  echo "ERROR: $msg"
  exit 1
}

TAG=$(git tag | grep -c "$VERSION")

if [[ "$TAG" -ne "0" ]]; then
  echo -n "Version $VERSION has already been tagged: "
  git tag | grep "$VERSION"
  exit 1
fi

OPTIMIZE_AUTOLOAD=""
if [ "$NO_OPT" != "--no-checkout" ]; then
  OPTIMIZE_AUTOLOAD=" --classmap-authoritative"
  BRANCH="stable/$VERSION"
  git checkout -b "$BRANCH" || fail "Version branch $BRANCH already exists"
else
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

git rm -rf vendor
rm -rf vendor
composer install$OPTIMIZE_AUTOLOAD || fail "composer install failed"
git add vendor
find asset/ -type f | xargs -L1 git add -f
echo "v$VERSION" > VERSION
git add VERSION
git commit -m "Version v$VERSION"

composer validate --no-check-all --strict || fail "Composer validate failed"

if [ -z "$NO_OPT" ]; then
  git tag -a v$VERSION -m "Version v$VERSION"
  echo "Finished, tagged v$VERSION"
  echo "Now please run:"
else
  echo "Finished, but not tagged yet"
  echo "Now please run:"
  echo "git tag -s v$VERSION -m \"Version v$VERSION\""
fi

echo "git push origin "$BRANCH":"$BRANCH" && git push --tags"
