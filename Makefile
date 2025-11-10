.PHONY: test

# デフォルトのシミュレータ設定
SCHEME = CaRetailBoosterSDK
SIMULATOR_NAME = iPhone 16 Pro
DESTINATION = platform=iOS Simulator,name=$(SIMULATOR_NAME)

test:
	@xcodebuild test \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		2>&1 | grep -E "(Test Suite|Test Case.*'|passed|failed|\*\* TEST|Executed)" || \
		xcodebuild test -scheme $(SCHEME) -destination '$(DESTINATION)'
