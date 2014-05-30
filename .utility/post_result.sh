trim() {
    local var=$@

    result=''

    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters

    result=$var
}

getValueFromKey(){
  str=$2
  pattern=$1
  result=''

  if [[ $str =~ ^($pattern)(.*)$ ]]; then
    #statements
    result=${BASH_REMATCH[2]}
    return 1
  fi

  return 0
}

getCurrentPullRequest(){
  local url_api=$1

  echo "curl -i https://api.github.com/users/whatever"
  curl -i 'https://api.github.com/users/whatever?client_id=d7f5c6567b209db57c67&client_secret=ba7ee1cd4879f8aad1c241723bf052cc058295d2'
  response=`curl -s $url_api | sed -e 's/\[/\(/g' -e 's/\]/\)/g' | awk -F: '/(\"html_url\"\:)|(\"state\"\:)|(\"ref\"\:)|(\"comments_url\")/ {print}'`
  
  OIFS=$IFS
  IFS=','
  comments_url=''
  tokens=($response)

  for (( i = 0; i < ${#tokens[@]}; i++ )); 
  do
    #statements
    tokens[$i]=`echo ${tokens[$i]} | tr -d ' ' | sed -e 's/\"//g'`
    trim ${tokens[$i]}
    tokens[$i]=$result

    if [[ ${tokens[$i]} =~ (ref\:)(.*) ]]; then
      getValueFromKey 'state:' ${tokens[$i-3]}
      local status=$result

      getValueFromKey 'html_url:' ${tokens[$i-4]}
      local repository=$result

      getValueFromKey 'comments_url:' ${tokens[$i-1]}
      local comments=$result

      getValueFromKey 'ref:' ${tokens[$i]}
      if [[ "$result" == "$branch" && "$status" == 'open' ]]; then
        #statements
        result=$repository
        comments_url=$comments
        return 1
      fi
    fi
  done    

  IFS=$OIFS

  return 0
}

generate_report(){
  osascript .utility/coverstory.scpt $TRAVIS_BUILD_DIR/coverage_report $HOME/coverage
}

push_2_report(){
  local dir_html=$1
  local name_branch=$2

  echo "dir_html=$dir_html"
  echo "name_branch=$name_branch"
  echo "------------------------"

  echo "Begin export report for $name_branch"

  # mkdir $HOME/report_$name_branch
  cp -R $dir_html $HOME/report_$name_branch
  cd $HOME

  git clone --depth=50 --branch=empty-template https://${report_token}@github.com/${report_repository}.git $HOME/${name_branch}_$TRAVIS_BUILD_NUMBER

  cd ${name_branch}_$TRAVIS_BUILD_NUMBER

  git remote add my_origin https://${report_token}@github.com/${report_repository}.git

  git checkout -b ci-report/feature/build_${name_branch}_$TRAVIS_BUILD_NUMBER
  git push -u my_origin ci-report/feature/build_${name_branch}_$TRAVIS_BUILD_NUMBER

  if [[ "$name_branch" == "analyzer" ]]; then
    #statements
    echo "copy all file of branch $name_branch"
    cp -R $HOME/report_$name_branch/*/ .
  else
    cp -R $HOME/report_$name_branch/ .
  fi

  link="ci-report/feature/build_${name_branch}_$TRAVIS_BUILD_NUMBER"

  git add -f .
  git commit -m "report build number $TRAVIS_BUILD_NUMBER for $name_branch pushed to travisci"
  git push -fq my_origin $link

  link="https://rawgit.com/${report_repository}${link}/index.html"

  echo "End export report for $name_branch"
}

set_git_info(){
  git config --global user.email "ngohoai.phuong@gmail.com"
  git config --global user.name "Travis"
}

push_comment_2_pullrequest(){
  message_str=$1
  echo "message:$message_str"
  curl -X POST -d "{\"body\":\"$message_str\"}" -H "Authorization: token ${GH_TOKEN}" $comments_url
}

save_report(){
  if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
    echo -e "Starting process data report"

    generate_report

    set_git_info
    local comment_string=''

    if [[ -d $HOME/coverage ]]; then
      #statements
      push_2_report $HOME/coverage "coverage"
      comment_string="[Run coverage completed, Click here to view report]($link)"
      echo "1.comments:$comment_string"
    fi

    if [[ -d $TRAVIS_BUILD_DIR/analyzer_report ]]; then
      #statements
      push_2_report $TRAVIS_BUILD_DIR/analyzer_report "analyzer"
      comment_string="${comment_string}\\n[Run analyzer completed, Click here to view report]($link)"
      echo "2.comments:$comment_string"
    fi

    if [[ "$comment_string" != '' ]]; then
      #statements
      echo "comments:$comment_string"
      push_comment_2_pullrequest $comment_string
    fi

    echo -e "End process data report"    
  fi
}

export REPO="$(pwd | sed s,^/home/travis/build/,,g)"
url_api='https://api.github.com/repos/'
branch=$TRAVIS_BRANCH
report_token=`perl -e "print pack 'H*','$1'"`
report_repository="vfa-travisci/travisci"

getValueFromKey '/Users/travis/build/' $TRAVIS_BUILD_DIR
if [[ "$?" == 1 ]]; then
  #statements
  url_api="${url_api}${result}/pulls"
  echo "url_api=$url_api"
  getCurrentPullRequest $url_api
  if [[ "$?" == 1 ]]; then
    #statements
    pull_request=$result
    echo "pull_request=$pull_request"
    save_report
  fi
fi

echo '-----------------------------'
echo "REPOSITORY=$REPO"
echo "TRAVIS_BUILD_DIR=$TRAVIS_BUILD_DIR"
echo "TRAVIS_REPO_SLUG=$TRAVIS_REPO_SLUG"
echo "BRANCH=$branch"
echo "GH_TOKEN=${GH_TOKEN}"
echo "TRAVIS_TOKEN=${report_token}"
echo '-----------------------------'