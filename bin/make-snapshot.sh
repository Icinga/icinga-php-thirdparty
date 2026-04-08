#!/bin/bash

set -xe

BRANCH="$1"

if [ -z $BRANCH ]; then
  echo "USAGE: $0 <branch>"
  echo " e.g.: $0 snapshot/nightly"
  exit 1
fi

LATEST_TAG=$(git for-each-ref refs/tags --sort=-v:refname --format='%(refname)' --count=1 | awk -F/ '{print $3}')
NEXT_VERSION=$(echo "${LATEST_TAG:1}" | awk -F. -v OFS=. '{$3=0}; {++$2}; {print}')

if [[ -n $(git branch | grep $BRANCH) ]]; then
  git branch -D $BRANCH
fi

git checkout -b $BRANCH

git merge --no-ff --no-commit -m "Merge latest tag, package pipelines require it" $LATEST_TAG || true
git restore -WS composer.json
git restore -WS composer.lock
git commit --no-edit

bin/make-release.sh "$NEXT_VERSION-dev" --no-checkout
