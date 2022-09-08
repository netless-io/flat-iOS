ARCHIVEPATH=$(find $(pwd)/Archive -name "*.xcarchive")
DSYMPATH=$ARCHIVEPATH/dSYMs
UPLOAD_TOOL_PATH=$(find $(pwd)/Pods/FirebaseCrashlytics -name "upload-symbols")
GOOGLESERVICE_PATH=$(find $(pwd)/Flat -name "GoogleService-Info.plist")
$UPLOAD_TOOL_PATH -gsp $GOOGLESERVICE_PATH -p ios $DSYMPATH