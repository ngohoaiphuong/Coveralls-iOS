wget http://clang-analyzer.llvm.org/downloads/checker-276.tar.bz2

tar -xvjf checker-276.tar.bz2

./checker-276/scan-build -o $ANALYZER_DIR xcodebuild -project "$APPNAME.xcodeproj" -configuration Debug -sdk iphonesimulator clean analyze 

.utility/save_report.sh $REPORT_TOKEN "analyzer"

rm -r $TRAVIS_BUILD_DIR/$ANALYZER_DIR