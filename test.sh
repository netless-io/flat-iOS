SCHEME=$1
OUTPATH=$2
xcodebuild \
  -workspace Flat.xcworkspace \
  -scheme $SCHEME \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhoneTest' \
  test | xcbeautify > $OUTPATH
  PASSSTR='Test Succeeded'
  TEST_RESULT=$(cat $OUTPATH)
  ISPASS=$(echo $TEST_RESULT | grep "${PASSSTR}")
  if [[ "$ISPASS" != "" ]]
  then
    echo "TEST Succeeded"
  else
    echo "TEST FAIL SEE $OUTPATH"
    exit 1
  fi