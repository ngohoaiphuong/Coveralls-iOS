export REPO="$(pwd | sed s,^/home/travis/build/,,g)"
echo -e "Current Repo:$REPO --- Travis Branch:$TRAVIS_BRANCH"
echo "TRAVIS_PULL_REQUEST = $TRAVIS_PULL_REQUEST"
echo "TRAVIS_BUILD_NUMBER = $TRAVIS_BUILD_NUMBER"
echo "GH_TOKEN = ${GH_TOKEN}"

if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  echo -e "Starting to update gh-pages\n"

  cp -R report $HOME/report
  cd $HOME

  git config --global user.email "ngohoai.phuong@gmail.com"
  git config --global user.name "Travis"

  git clone --depth=50 --branch=ci-report/template git://github.com/${TRAVIS_REPO_SLUG}.git $HOME/$TRAVIS_BUILD_NUMBER

  cd $TRAVIS_BUILD_NUMBER

  git remote -v

  git checkout -b ci-report/feature/build_$TRAVIS_BUILD_NUMBER
  git push -u origin ci-report/feature/build_$TRAVIS_BUILD_NUMBER

  cp -R $HOME/report/*/ .

#   cd gh-pages
#   cp -Rf $HOME/coverage/* .

  git add -f .
  git commit -m "Travis build $TRAVIS_BUILD_NUMBER pushed to gh-pages"
  git push -fq origin ci-report/feature/build_$TRAVIS_BUILD_NUMBER

  echo -e "Done magic with coverage\n"
fi