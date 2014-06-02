# svn checkout http://coverstory.googlecode.com/svn/trunk/ "$HOME/coverstory-read-only"

# xcodebuild build -project $HOME/coverstory-read-only/CoverStory.xcodeproj CONFIGURATION_BUILD_DIR="/Applications"

# rm -r "$HOME/coverstory-read-only"

# xcodebuild clean test -sdk iphonesimulator -project Coveralls-iOS.xcodeproj -scheme ci -configuration Debug OBJROOT=coverage_report ONLY_ACTIVE_ARCH=NO GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES

echo '------------'
echo $APPNAME
echo $COVERAGE_DIR
echo '------------'