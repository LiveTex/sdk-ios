
xcodebuild archive \
  -scheme LivetexCore \
  -sdk iphoneos \
  -archivePath "./iphoneos.xcarchive" \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

xcodebuild archive \
  -scheme LivetexCore \
  -sdk iphonesimulator \
  -archivePath "./iphonesimulator.xcarchive" \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

xcodebuild -create-xcframework \
    -framework "./iphoneos.xcarchive/Products/Library/Frameworks/LivetexCore.framework" \
    -framework "./iphonesimulator.xcarchive/Products/Library/Frameworks/LivetexCore.framework" \
    -output "./LivetexCore.xcframework"

rm -rf iphoneos.xcarchive
rm -rf iphonesimulator.xcarchive