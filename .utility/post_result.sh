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
  url_api=$1

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

    if [[ ${tokens[$i]} =~ (ref\:) ]]; then
      getValueFromKey 'state:' ${tokens[$i-3]}
      local status=$result

      getValueFromKey 'html_url:' ${tokens[$i-4]}
      local repository=$result

      getValueFromKey 'comments_url:' ${tokens[$i-1]}
      local comments=$result

      getValueFromKey 'ref:' ${tokens[$i]}
      if [[ $? == 1 && $result == $branch && $status == 'open' ]]; then
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
  ls '/Applications/CoverStory.app'
  osascript .utility/coverstory.scpt coverage_report $HOME/coverage
}

save_report(){
  if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
    echo -e "Starting process data report\n"
    generate_report
    echo -e "End process data report\n"    
  fi
}

export REPO="$(pwd | sed s,^/home/travis/build/,,g)"
url_api='https://api.github.com/repos/'
branch=$TRAVIS_BRANCH

getValueFromKey '/Users/travis/build/' $TRAVIS_BUILD_DIR
if [[ $? == 1 ]]; then
  #statements
  url_api="${url_api}${result}/pulls"

  getCurrentPullRequest $url_api
  if [[ $? == 1 ]]; then
    #statements
    pull_request=$result
    save_report
  fi
fi

echo '-----------------------------'
echo "REPOSITORY=$REPO"
echo "TRAVIS_BUILD_DIR=$TRAVIS_BUILD_DIR"
echo "TRAVIS_REPO_SLUG=$TRAVIS_REPO_SLUG"
echo "BRANCH=$branch"
echo "GH_TOKEN=${GH_TOKEN}"
echo "TRAVIS_TOKEN=${TRAVIS_TOKEN}"
echo '-----------------------------'