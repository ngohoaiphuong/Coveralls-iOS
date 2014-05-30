export REPO="$(pwd | sed s,^/home/travis/build/,,g)"
token="14266bb42129ae71c1412dcf0d0623b46b580986"
gh_token=$1

echo -e "Current Repo:$REPO --- Travis Branch:$TRAVIS_BRANCH"
echo "TRAVIS_PULL_REQUEST = $TRAVIS_PULL_REQUEST"
echo "TRAVIS_BUILD_NUMBER = $TRAVIS_BUILD_NUMBER"
echo "GH_TOKEN = $gh_token"
list=`curl https://api.github.com/repos/ngohoaiphuong/Coveralls-iOS/pulls`
echo '---------'
# echo $list
echo ">>>>>>GH_TOKEN=${GH_TOKEN}"

if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  echo -e "Starting to update gh-pages\n"

  cp -R report $HOME/report
  cd $HOME

  git config --global user.email "ngohoai.phuong@gmail.com"
  git config --global user.name "Travis"

  git clone --depth=50 --branch=ci-report/template https://14266bb42129ae71c1412dcf0d0623b46b580986@github.com/${TRAVIS_REPO_SLUG}.git $HOME/$TRAVIS_BUILD_NUMBER

  cd $TRAVIS_BUILD_NUMBER

  git remote -v

  git remote add my_origin https://14266bb42129ae71c1412dcf0d0623b46b580986@github.com/${TRAVIS_REPO_SLUG}.git

  git checkout -b ci-report/feature/build_$TRAVIS_BUILD_NUMBER
  git push -u my_origin ci-report/feature/build_$TRAVIS_BUILD_NUMBER

  cp -R $HOME/report/*/ .

#   cd gh-pages
#   cp -Rf $HOME/coverage/* .

  git add -f .
  git commit -m "Travis build $TRAVIS_BUILD_NUMBER pushed to gh-pages"
  git push -fq my_origin ci-report/feature/build_$TRAVIS_BUILD_NUMBER

  echo -e "Done magic with coverage\n"
fi

message_str="[Click here to view report](https://rawgit.com/ngohoaiphuong/Coveralls-iOS/ci-report/feature/build_$TRAVIS_BUILD_NUMBER/index.html)"
# curl -X POST -d "{\"body\":\"test add comment\"}" -H 'Authorization: token 14266bb42129ae71c1412dcf0d0623b46b580986' https://api.github.com/repos/ngohoaiphuong/Coveralls-iOS/issues/2/comments
curl -X POST -d "{\"body\":\"$message_str\"}" -H "Authorization: token ${GH_TOKEN}" https://api.github.com/repos/ngohoaiphuong/Coveralls-iOS/issues/2/comments

