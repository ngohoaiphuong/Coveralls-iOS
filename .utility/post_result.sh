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

  mkdir $HOME/report_$name_branch
  cp -R $dir_html $HOME/report_$name_branch
  cd $HOME

  echo "CMD:https://${report_token}@github.com/${report_repository}.git $HOME/${name_branch}_$TRAVIS_BUILD_NUMBER"
  git clone --depth=50 --branch=empty-template https://${report_token}@github.com/${report_repository}.git $HOME/${name_branch}_$TRAVIS_BUILD_NUMBER

  cd ${name_branch}_$TRAVIS_BUILD_NUMBER

  git remote -v

  git remote add my_origin https://${report_token}@github.com/${report_repository}.git

  git checkout -b ci-report/feature/build_${name_branch}_$TRAVIS_BUILD_NUMBER
  git push -u my_origin ci-report/feature/build_${name_branch}_$TRAVIS_BUILD_NUMBER

  if [[ "$name_branch" == "analyzer" ]]; then
    #statements
    cp -R $HOME/report_$name_branch/*/ .
  else
    cp -R $HOME/report_$name_branch/ .
  fi

  git add -f .
  git commit -m "report build number $TRAVIS_BUILD_NUMBER for $name_branch pushed to travisci"
  git push -fq my_origin ci-report/feature/build_${name_branch}_$TRAVIS_BUILD_NUMBER

  echo "End export report for $name_branch"
}

set_git_info(){
  git config --global user.email "ngohoai.phuong@gmail.com"
  git config --global user.name "Travis"
}

save_report(){
  if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
    echo -e "Starting process data report"

    generate_report

    set_git_info

    if [[ -d $HOME/coverage ]]; then
      #statements
      push_2_report $TRAVIS_BUILD_DIR/coverage_report "coverage"
    fi

    if [[ -d $TRAVIS_BUILD_DIR/analyzer_report ]]; then
      #statements
      push_2_report $TRAVIS_BUILD_DIR/analyzer_report "analyzer"
    fi

    echo -e "End process data report"    
  fi
}

export REPO="$(pwd | sed s,^/home/travis/build/,,g)"
url_api='https://api.github.com/repos/'
branch=$TRAVIS_BRANCH
report_token=`perl -e "print pack 'H*','$1'"`
report_repository="vfa-travisci/travisci.git"

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