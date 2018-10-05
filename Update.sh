swift package update
swift package generate-xcodeproj --output ".build/xcode/"
swift package generate-xcodeproj --output ".build/xcode/ios" --xconfig-overrides "BookishCoreiOS.xcconfig"
