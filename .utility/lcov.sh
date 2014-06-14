git clone https://github.com/linux-test-project/lcov.git $HOME/lcov

if [[ ! -d $HOME/lcov ]]; then
  #statements
  echo "Can't install lcov tool, please try another time"
  exit 1
fi

LCOV_HOME=$HOME/lcov
export PATH=$LCOV_HOME/bin:$PATH
