wget http://archives.oclint.org/nightly/oclint-0.9.dev.43e26f7-x86_64-darwin-12.4.0.tar.gz
tar -xvzf oclint-0.9.dev.43e26f7-x86_64-darwin-12.4.0.tar.gz &> /dev/null

if [[ ! -d oclint-0.9.dev.43e26f7 ]]; then
	echo "Can't install OClint tool, please try another time"
	exit 1
fi

OCLINT_HOME=$TRAVIS_BUILD_DIR/oclint-0.9.dev.43e26f7
export PATH=$OCLINT_HOME/bin:$PATH

echo '---------------checking exists oclint--------------'
which oclint
echo '---------------------------------------------------'