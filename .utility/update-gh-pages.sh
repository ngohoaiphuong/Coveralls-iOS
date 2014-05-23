export REPO="$(pwd | sed s,^/home/travis/build/,,g)"
echo -e "Current Repo:$REPO --- Travis Branch:$TRAVIS_BRANCH"
echo "TRAVIS_PULL_REQUEST = $TRAVIS_PULL_REQUEST"
echo "TRAVIS_BUILD_NUMBER = $TRAVIS_BUILD_NUMBER"

if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  echo -e "Starting to update gh-pages\n"

  cp -R report $HOME/coverage

  cd $HOME
  git config --global user.email "ngohoai.phuong@gmail.com"
  git config --global user.name "Travis"

  cd gh-pages
  cp -Rf $HOME/coverage/* .

  git add -f .
  git commit -m "Travis build $TRAVIS_BUILD_NUMBER pushed to gh-pages"
  git push -fq origin gh-pages > /dev/null

  echo -e "Done magic with coverage\n"
fi