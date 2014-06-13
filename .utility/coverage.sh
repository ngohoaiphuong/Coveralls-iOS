svn checkout http://coverstory.googlecode.com/svn/trunk/ "$HOME/coverstory-read-only"

xcodebuild build -project $HOME/coverstory-read-only/CoverStory.xcodeproj CONFIGURATION_BUILD_DIR="/Applications"

rm -r "$HOME/coverstory-read-only"

xcodebuild clean test -sdk iphonesimulator -project "$APPNAME.xcodeproj" -scheme ci -configuration Debug OBJROOT=$COVERAGE_DIR ONLY_ACTIVE_ARCH=NO GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES

.utility/save_report.sh $REPORT_TOKEN "coverage"

rm -r $TRAVIS_BUILD_DIR/$COVERAGE_DIR