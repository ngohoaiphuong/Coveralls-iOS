export REPO="$(pwd | sed s,^/home/travis/build/,,g)"

echo '-----------------------------'
echo "REPOSITORY=$REPO"
echo "TRAVIS_BUILD_DIR=$TRAVIS_BUILD_DIR"
echo "TRAVIS_REPO_SLUG=$TRAVIS_REPO_SLUG"
echo "GH_TOKEN=${GH_TOKEN}"
echo '-----------------------------'