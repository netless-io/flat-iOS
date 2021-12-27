buildname=$(date +%s)
archivename=$buildname.xcarchive
archivepath=./Archive/$archivename
ipapath=./iPa
scheme=Flat-PROD
configuration=Release
xcodebuild archive -workspace Flat.xcworkspace -scheme $scheme -configuration $configuration -archivePath $archivepath -destination generic/platform=iOS
xcodebuild -exportArchive -archivePath $archivepath -exportOptionsPlist export_release.plist -exportPath $ipapath
