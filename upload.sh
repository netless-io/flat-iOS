export PATH=$PATH:/Applications/Xcode.app/Contents/Developer/usr/bin/
cd iPa
IPA=$(find . -name '*.ipa')
altool --upload-app -t ios -f $IPA -u $1 -p $2
shasum -a 256 $(IPA)