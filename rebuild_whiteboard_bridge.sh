set -exo pipefail
ENTRY_PATH=$1
LOCAL_PATH=$(echo ~/Desktop/Whiteboard/Whiteboard-iOS/Whiteboard/Resource)
POD_PATH="${ENTRY_PATH}/Pods/Whiteboard/Whiteboard/Resource"
if test -d $POD_PATH
then
    WHITE_RESOURCE_PATH=$POD_PATH
    REMOVE_RAW_SOURCE=1
elif test -d $LOCAL_PATH
then
    WHITE_RESOURCE_PATH=$LOCAL_PATH
    REMOVE_RAW_SOURCE=0
else
    echo "Whiteboard resource path not found"
    exit 1
fi
echo "Whiteboard resource path: $WHITE_RESOURCE_PATH"

curl -sSL https://raw.githubusercontent.com/netless-io/flat-native-bridge/main/bridge.sh | sh -s $WHITE_RESOURCE_PATH

BUILD_PATH=$ENTRY_PATH/build
BUNDLE_PATH=$ENTRY_PATH/Flat/whiteboard_rebuild.bundle
rm -r $BUNDLE_PATH/*

cp -r $BUILD_PATH/* $BUNDLE_PATH
rm -rf $BUILD_PATH

if test $REMOVE_RAW_SOURCE -eq 1
then
    rm -rf $WHITE_RESOURCE_PATH/*.html
    rm -rf $WHITE_RESOURCE_PATH/*.js
    rm -rf $WHITE_RESOURCE_PATH/*.css
fi