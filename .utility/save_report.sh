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
  echo "osascript .utility/coverstory.scpt $TRAVIS_BUILD_DIR/coverage_report $HOME/coverage"
  osascript .utility/coverstory.scpt $TRAVIS_BUILD_DIR/coverage_report $HOME/coverage
}

push_2_report(){
  local dir_html=$1
  local name_branch=$2

  echo "dir_html=$dir_html"
  echo "name_branch=$name_branch"
  echo "------------------------"

  echo "Begin export report for $name_branch"

  cp -R $dir_html $HOME/report_$name_branch
  cd $HOME
  rm -rf $dir_html

  git clone --depth=50 --branch=empty-template https://${report_token}@github.com/${report_repository}.git $HOME/${name_branch}_$TRAVIS_BUILD_NUMBER

  cd ${name_branch}_$TRAVIS_BUILD_NUMBER

  git remote add my_origin https://${report_token}@github.com/${report_repository}.git

  if [[ "$name_branch" == "analyzer" ]]; then
    #statements
    link=$analyzer_branch
  else
    link=$coverage_branch
  fi

  git checkout -b $link
  git push -u my_origin $link
  
  link="ci-report/feature/build_${name_branch}_$TRAVIS_BUILD_NUMBER"


  if [[ "$name_branch" == "analyzer" ]]; then
    #statements
    echo "copy all file of branch $name_branch"
    cp -R $HOME/report_$name_branch/*/ .
    link=$analyzer_branch
  else
    cp -R $HOME/report_$name_branch/ .
    link=$coverage_branch
  fi

  rm -rf $HOME/report_$name_branch

  git add -f .
  git commit -m "report build number $TRAVIS_BUILD_NUMBER for $name_branch pushed to travisci"
  git push -fq my_origin $link

  link_repository="https://github.com/${report_repository}/tree/${link}"
  link="https://rawgit.com/${report_repository}/${link}/index.html"

  echo "End export report for $name_branch"
  
  #remove all data
  cd $HOME

  rm -rf $HOME/${name_branch}_$TRAVIS_BUILD_NUMBER
}

set_git_info(){
  git config --global user.email "ngohoai.phuong@gmail.com"
  git config --global user.name "Travis"
}

push_comment_2_pullrequest(){
  # message_str="[Analyzer completed]($2) [Run coverage completed]($1)"
  # curl -X POST -d "{\"body\":\"${message_str}\"}" -H "Authorization: token ${GH_TOKEN}" $comments_url
  message_html="<html><div><a href='$1' target='_blank'>Measure Coverage Result</a></div><div><a href='$2' target='_blank'>Analyzer Result</a></div></html>"
  curl -X POST -d "{\"body\":\"${message_html}\"}" -H "Authorization: token ${GH_TOKEN}" $comments_url
}

push_comment_2_slack(){
  coverage_link="https://rawgit.com/${report_repository}/${coverage_branch}/index.html"
  coverage_repository="https://github.com/${report_repository}/tree/${coverage_branch}"

  analyzer_link="https://rawgit.com/${report_repository}/${analyzer_branch}/index.html"
  analyzer_repository="https://github.com/${report_repository}/tree/${analyzer_branch}"

  echo "coverage_link=$coverage_link"
  echo "coverage_repository=$coverage_repository"
  echo "----------"
  echo "analyzer_link=$analyzer_link"
  echo "analyzer_repository=$analyzer_repository"

  payload="{\"channel\":\"#${slack_channel}\", \"username\": \"Travis CI\", \"text\":\"Coverage and Analyzer code completed\""
  payload="${payload},\"attachments\":[{\"pretext\":\"You can get coverage build directory $1\",\"fields\":[{\"title\":\"Notes\",\"value\":\"You can view result online at $2\"}]}, {\"pretext\":\"You can get analyzer build directory $3\",\"fields\":[{\"title\":\"Notes\",\"value\":\"You can view result online at $4\"}]}]"
  payload="${payload},\"icon_url\":\"https://s3-us-west-2.amazonaws.com/slack-files2/bot_icons/2014-05-22/2351865235_48.png\"}"

  cmd="curl -X POST --data-urlencode 'payload=${payload}' https://ygo.slack.com/services/hooks/incoming-webhook\?token\=lz25ioqy6NTAUO4BshDh2yWb"
  echo $cmd
  # eval $cmd
}

save_report(){
  local which_branch=$1
  if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
    echo -e "Starting process data report"

    if [[ "$which_branch" == 'coverage' ]]; then
      #statements
      generate_report
    fi

    set_git_info

    if [[ -d $HOME/coverage && "$which_branch" == 'coverage' ]]; then
      #statements
      push_2_report $HOME/coverage "coverage"
      coverage_link=$link
      export COVERAGE_LINK='ngohoai'
      coverage_repository=$link_repository
    fi

    if [[ -d $TRAVIS_BUILD_DIR/analyzer_report  && "$which_branch" == 'analyzer' ]]; then
      #statements
      push_2_report $TRAVIS_BUILD_DIR/analyzer_report "analyzer"
      analyzer_link=$link
      analyzer_repository=$link_repository
    fi

    # if [[ "$coverage_link" != '' ]]; then
    #   #statements
    #   # push_comment_2_pullrequest $coverage_link $analyzer_link
    #   push_comment_2_slack $coverage_repository $coverage_link $analyzer_repository $analyzer_link
    # fi

    # if [[ "$analyzer_link" != '' ]]; then
    #   #statements
    #   # push_comment_2_pullrequest $coverage_link $analyzer_link
    #   push_comment_2_slack $coverage_repository $coverage_link $analyzer_repository $analyzer_link
    # fi

    echo -e "End process data report"    
  fi
}

export REPO="$(pwd | sed s,^/home/travis/build/,,g)"
url_api='https://api.github.com/repos/'
branch=$TRAVIS_BRANCH
report_token=`perl -e "print pack 'H*','$1'"`
report_repository="vfa-travisci/travisci"

coverage_branch="test-report/${branch}/coverage/build_${TRAVIS_BUILD_NUMBER}"
analyzer_branch="test-report/${branch}/analyzer/build_${TRAVIS_BUILD_NUMBER}"
slack_channel=$SLACK_CHANNEL

echo '-----------------------------'
echo "REPOSITORY=$REPO"
echo "TRAVIS_BUILD_DIR=$TRAVIS_BUILD_DIR"
echo "TRAVIS_REPO_SLUG=$TRAVIS_REPO_SLUG"
echo "BRANCH=$branch"
echo "GH_TOKEN=${GH_TOKEN}"
echo "TRAVIS_TOKEN=${report_token}"
echo "coverage_branch=${coverage_branch}"
echo "analyzer_branch=${analyzer_branch}"
echo '-----------------------------'

if [[ "$2" == "send_message" ]]; then
  #statements
  push_comment_2_slack $COVERAGE_REPOSITORY $COVERAGE_LINK $ANALYZER_REPOSITORY $ANALYZER_LINK
else
  save_report $2
fi

# push_comment_2_slack $coverage_branch $analyzer_branch