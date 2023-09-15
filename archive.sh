buildname=$(date +%s)
archivename=$buildname.xcarchive
archivepath=./Archive/$archivename
ipapath=./iPa
scheme=$1
configuration=$2
exportOptionsPlist=$3
xcodebuild archive -workspace Flat.xcworkspace -scheme $scheme -configuration $configuration -archivePath $archivepath -destination generic/platform=iOS
xcodebuild -exportArchive -archivePath $archivepath -exportOptionsPlist $exportOptionsPlist -exportPath $ipapath
