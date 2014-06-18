# wget http://archives.oclint.org/releases/0.7/oclint-0.7-x86_64-apple-darwin-10.tar.gz &> /dev/null

wget http://archives.oclint.org/releases/0.7/oclint-0.7-x86_64-apple-darwin-10.tar.gz
tar -xvjf oclint-0.7-x86_64-apple-darwin-10.tar.gz &> /dev/null

if [[ ! -d oclint-0.7-x86_64-apple-darwin-10 ]]; then
	#statements
	echo "Can't install OClint tool, please try another time"
	exit 1
fi

OCLINT_HOME=$TRAVIS_BUILD_DIR/oclint-0.7-x86_64-apple-darwin-10
export PATH=$OCLINT_HOME/bin:$PATH