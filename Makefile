bootstrap:
ifeq ($(strip $(shell command -v brew 2> /dev/null)),)
	$(error "`brew` is not available, please install homebrew")
endif
ifeq ($(strip $(shell command -v xcodegen 2> /dev/null)),)
	brew install xcodegen
endif
ifeq ($(strip $(shell command -v swiftformat 2> /dev/null)),)
	brew install swiftformat
endif

carthage-project:
	xcodegen generate

format:
	swiftformat . 2> /dev/null

framework:
	rm -rf ./build
	echo 'Creating Xcode project...'
	xcodegen generate

	# Archive with xcodebuild
	echo 'Build iOS Framework...'
	xcodebuild clean archive \
		-project TinkCore.xcodeproj \
		-scheme TinkCore_iOS \
		-destination generic/platform=iOS \
		-archivePath ./build/ios.xcarchive \
		-sdk iphoneos \
		SKIP_INSTALL=NO \
		BUILD_LIBRARY_FOR_DISTRIBUTION=YES

	echo 'Build iOS Simulator Framework...'
	xcodebuild clean archive \
		-project TinkCore.xcodeproj \
		-scheme TinkCore_iOS \
		-destination 'generic/platform=iOS Simulator' \
		-archivePath ./build/iossimulator.xcarchive \
		-sdk iphonesimulator \
		SKIP_INSTALL=NO \
		BUILD_LIBRARY_FOR_DISTRIBUTION=YES

	# Create XCFramework
	echo 'Assemble Frameworks...'
	xcodebuild -create-xcframework \
		-framework ./build/ios.xcarchive/Products/Library/Frameworks/TinkCore.framework \
		-framework ./build/iossimulator.xcarchive/Products/Library/Frameworks/TinkCore.framework \
		-output ./build/TinkCore.xcframework
