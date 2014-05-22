echo "$TRAVIS_PULL_REQUEST"
if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  echo -e "Starting to update gh-pages\n"

  cp -R report $HOME/coverage

  cd $HOME
  git config --global user.email "ngohoai.phuong@gmail.com"
  git config --global user.name "Travis"
  git clone --quiet --branch=gh-pages https://${GH_TOKEN}@github.com/ngohoaiphuong/Coveralls-iOS.git  gh-pages > /dev/null

  cd gh-pages
  cp -Rf $HOME/coverage/* .

  git add -f .
  git commit -m "Travis build $TRAVIS_BUILD_NUMBER pushed to gh-pages"
  git push -fq origin gh-pages > /dev/null

  echo -e "Done magic with coverage\n"
fi