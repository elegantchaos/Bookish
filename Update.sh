swift package update
rm -rf ".build/xcode"

swift package generate-xcodeproj --output ".build/xcode/mac" --xcconfig-overrides "BookishCoreMac.xcconfig"
#mv .build/xcode/mac/BookishCore.xcodeproj .build/xcode/mac/BookishCoreMac.xcodeproj

swift package generate-xcodeproj --output ".build/xcode/mobile" --xcconfig-overrides "BookishCoreMobile.xcconfig"
#mv .build/xcode/mobile/BookishCore.xcodeproj .build/xcode/mobile/BookishCoreMobile.xcodeproj
