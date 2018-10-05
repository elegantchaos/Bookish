swift package update
rm -rf ".build/xcode"

swift package generate-xcodeproj --output ".build/xcode/mac" --xcconfig-overrides "Configs/BookishCoreMac.xcconfig"
swift package generate-xcodeproj --output ".build/xcode/mobile" --xcconfig-overrides "Configs/BookishCoreMobile.xcconfig"
