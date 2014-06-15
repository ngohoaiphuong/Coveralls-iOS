check_analyzer_result(){
  if [[ ! -f $analyze_file ]]; then
    echo "Create analyze report fail"
    exit 1
  fi
}

make_build_coverage(){
  # initial information for begin parse coverage from gcda
  $HOME/lcov/bin/lcov --gcov-tool $gcov_path --capture --initial --directory $TRAVIS_BUILD_DIR/build --rc lcov_branch_coverage=1 --output-file $base_info > $log_file
  if [[ ! -f "$base_info" ]]; then
    #statements
    cat $log_file
    exit 1
  fi

  # get information from file gcda
  $HOME/lcov/bin/lcov --gcov-tool $gcov_path --capture --directory build --rc lcov_branch_coverage=1 --output-file $info > $log_file
  if [[ ! -f "$info" ]]; then
    #statements
    cat $log_file
    exit 1
  fi

  # get detail data from above information
  $HOME/lcov/bin/lcov --gcov-tool $gcov_path --add-tracefile $base_info --add-tracefile $info --output-file $total --rc lcov_branch_coverage=1  > $log_file
  if [[ ! -f "$total" ]]; then
    #statements
    cat $log_file
    exit 1
  fi

  # set filter some source code need don't show or don't build coverage
  $HOME/lcov/bin/lcov --gcov-tool $gcov_path --remove $total $pattern -o $filter --rc lcov_branch_coverage=1 > $log_file
  if [[ ! -f "$filter" ]]; then
    #statements
    cat $log_file
    exit 1
  fi

  # generate information from filter info file into html report
  $HOME/lcov/bin/genhtml --ignore-errors source $filter --legend --title "Coverage Code" --branch-coverage --output-directory $coverage > $log_file
  if [[ ! -d "$coverage" ]]; then
    #statements
    cat $log_file
    exit 1
  fi

  # show summary after build html success
  cat $log_file | egrep "lines\.+\:|functions\.+\:|branches\.+\:"
}

deploy_to_s3(){
  echo "Prepare deploy to S3"
  echo '*list directory report'
  ls -R report
  echo "*list directory path_s3=$path_s3"
  ls -R $path_s3

  if [[ -f $analyze_file ]]; then
    #statements
    cp $analyze_file $path_s3/analyzer/index.html
  fi

  # move result to target
  mv $coverage $path_s3
  mv $ygo_name target/
  echo "*list directory target"
  ls -R target
}

send_message_to_slack(){
  local summary=`cat $log_file | egrep "lines\.+\:|functions\.+\:|branches\.+\:"`
  local lines=`echo $summary | sed -e "s/ functions\.*\:[^\)]*) //g" -e "s/branches\.*\:[^\)]*)//g" -e "s/^ //g" -e "s/ $//g"`
  local functions_=`echo $summary | sed -e "s/lines\.*\:[^\)]*) //g" -e "s/ branches\.*\:[^\)]*)//g" -e "s/^ //g" -e "s/ $//g"`
  local branches=`echo $summary | sed -e "s/lines\.*\:[^\)]*) //g" -e "s/ functions\.*\:[^\)]*)//g" -e "s/^ //g" -e "s/ $//g"`

  local coverage_link="https://s3.amazonaws.com/ygo-development/artifacts/${path_s3}/coverage/index.html"
  local analyzer_link="https://s3.amazonaws.com/ygo-development/artifacts/${path_s3}/analyzer/index.html"

  echo '--------report--------'
  echo $summary
  echo "lines:$lines"
  echo "functions:$functions"
  echo "branches:$branches"
  echo '----------------------'

  payload="{\"channel\":\"#${SLACK_CHANNEL}\", \"username\": \"Travis CI\", \"text\":\"Coverage and Analyzer code completed\""
  payload="${payload},\"attachments\":[{\"pretext\":\"You can view more detail Coverage reports at ${coverage_link}\", \"fields\":[{\"value\":\"$lines\", \"short\":false}"
  payload="${payload},{\"value\":\"$functions_\", \"short\":false}, {\"value\":\"$branches\", \"short\":false}]}, {\"pretext\":\"You can view more detail Analyzer reports at ${analyzer_link}\"}]"
  payload="${payload},\"icon_url\":\"https://s3-us-west-2.amazonaws.com/slack-files2/bot_icons/2014-05-22/2351865235_48.png\"}"

  cmd="curl -X POST --data-urlencode 'payload=${payload}' https://ygo.slack.com/services/hooks/incoming-webhook\?token\=lz25ioqy6NTAUO4BshDh2yWb"
  echo $cmd
  # eval $cmd

}

init_enviroment(){
  log_file='report/log.txt'
  gcov_path=`which gcov`
  base_info='report/base.info'
  info='report/info.info'
  total='report/total.info'
  pattern="'/Applications/Xcode.app/*' '*/Pods/*' '*/Library/Helper/*'"
  filter='report/filter.info'
  coverage='report/coverage'
  analyze_file="$TRAVIS_BUILD_DIR/report/analyze.html"
  ygo_name="YGO-iOS2"
}

init_s3_dir(){
  local s3YGO="s3/${ygo_name}"
  local branch=`echo $TRAVIS_BRANCH | sed -e 's/.*\///g'`

  # https://s3.amazonaws.com/ygo-development/artifacts/YGO-iOS2/8139-8076_run_coverage_analyze/784/coverage/index.html
  
  path_s3="${ygo_name}/${branch}/${TRAVIS_BUILD_NUMBER}"

  mkdir -p $path_s3/analyzer
}

init_enviroment
init_s3_dir

if [[ "$1" == "analyzer" ]]; then
  check_analyzer_result
elif [[ "$1" == "coverage" ]]; then
  make_build_coverage
elif [[ "$1" == "deploy" ]]; then
  deploy_to_s3
elif [[ "$1" == "message" ]]; then
  #statements
  send_message_to_slack
fi
