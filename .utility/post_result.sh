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
    return true
  fi

  return false
}

getCurrentPullRequest(){
  local url_api=$1

  echo ">url=$url_api"
  echo "curl -i https://api.github.com/users/whatever"
  curl -i https://api.github.com/users/whatever
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
      echo "result=${BASH_REMATCH[2]}"
      echo "$?|token=${tokens[$i]}|$result|$branch|$status|$repository"
      if [[ "$result" == "$branch" && "$status" == 'open' ]]; then
        #statements
        result=$repository
        comments_url=$comments
        echo "::>>>comments_url>>>$comments_url"
        return true
      fi
    fi
  done    

  IFS=$OIFS

  return false
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
      push_2_report analyzer_report "analyzer"
    fi

    echo -e "End process data report"    
  fi
}

export REPO="$(pwd | sed s,^/home/travis/build/,,g)"
url_api='https://api.github.com/repos/'
branch=$TRAVIS_BRANCH

getValueFromKey '/Users/travis/build/' $TRAVIS_BUILD_DIR
if [[ "$?" == true ]]; then
  #statements
  url_api="${url_api}${result}/pulls"
  echo "url_api=$url_api"
  getCurrentPullRequest $url_api
  echo "result=$?"
  if [[ "$?" == true ]]; then
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
echo "TRAVIS_TOKEN=${REPORT_TOKEN}"
echo '-----------------------------'