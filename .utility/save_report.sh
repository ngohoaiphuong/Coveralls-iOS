check_analyzer_result(){
  analyze_file="$TRAVIS_BUILD_DIR/report/analyze.html"
  if [[ -f $analyze_file ]]; then
    #statements
    cp $analyze_file $path_s3/analyzer
  else
    echo "Create analyze report fail"
    exit 1
  fi
}

make_build_coverage(){
  log_file='report/log.txt'
  gcov_path=`which gcov`
  base_info='report/base.info'
  info='report/info.info'
  total='report/total.info'
  pattern="'/Applications/Xcode.app/*' '*/Pods/*' '*/Library/Helper/*'"
  filter='report/filter.info'
  coverage='report/coverage'

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
  $SUMMARY=`cat $log_file | egrep "lines\.+\:|functions\.+\:|branches\.+\:"`
  mv $coverage $path_s3
}

deploy_and_send_to_slack(){
  echo '==============='
  echo $path_s3
  echo $SUMMARY
  ls -R report | grep ":" | sed -e 's/://' -e 's/[^-][^\/]*\//--/g'
  echo '---------------'
  ls -R $path_s3 | grep ":" | sed -e 's/://' -e 's/[^-][^\/]*\//--/g'
}

init_s3_dir(){
  local ygo_name="YGO-iOS2"
  local s3YGO="s3/${ygo_name}"
  local branch=`echo $TRAVIS_BRANCH | sed -e 's/.*\///g'`

  # https://s3.amazonaws.com/ygo-development/artifacts/YGO-iOS2/8139-8076_run_coverage_analyze/784/coverage/index.html
  
  path_s3="${ygo_name}/${branch}/${TRAVIS_BUILD_NUMBER}"

  mkdir -p $path_s3/analyzer
}


init_s3_dir

if [[ "$1" == "analyzer" ]]; then
  check_analyzer_result
elif [[ "$1" == "coverage" ]]; then
  make_build_coverage
elif [[ "$1" == "post" ]]; then
  deploy_and_send_to_slack
fi
