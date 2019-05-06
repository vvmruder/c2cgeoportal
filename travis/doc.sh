#!/bin/bash -ex

./docker-run make -f travis.mk doc

BRANCH=2.2

echo == Build the doc ==

git fetch origin gh-pages:gh-pages
git checkout gh-pages

mkdir --parent ${BRANCH}
mv doc/_build/html/* ${BRANCH}|true

git add --all ${BRANCH}
git commit --amend --message="Update documentation for the revision ${TRAVIS_COMMIT}" | true
git push --force origin gh-pages

# back to the original branch
git checkout ${GIT_REV}
