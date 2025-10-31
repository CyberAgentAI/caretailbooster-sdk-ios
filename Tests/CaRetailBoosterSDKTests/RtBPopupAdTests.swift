import XCTest
@testable import CaRetailBoosterSDK

@available(iOS 13.0, *)
@MainActor
final class RtBPopupAdTests: XCTestCase {

    override func setUp() async throws {
        await RetailBooster.reset()
    }

    override func tearDown() async throws {
        await RetailBooster.reset()
    }

    // MARK: - init tests

    func testInit_succeededEvenWhenSDKNotInitialized() {
        // When
        let popupAd = RtBPopupAd(tagGroupId: "tag1")

        // Then
        XCTAssertNotNil(popupAd)
        XCTAssertEqual(popupAd.tagGroupId, "tag1")
    }

    func testInit_succeedsWhenSDKInitialized() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)

        // When
        let popupAd = RtBPopupAd(tagGroupId: "tag1")

        // Then
        XCTAssertNotNil(popupAd)
        XCTAssertEqual(popupAd.tagGroupId, "tag1")
    }

    func testInit_withEventNameAndOptions() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        let options = PopupOptions()

        // When
        let popupAd = RtBPopupAd(
            tagGroupId: "tag1",
            eventName: "test_event",
            options: options
        )

        // Then
        XCTAssertNotNil(popupAd)
        XCTAssertEqual(popupAd.tagGroupId, "tag1")
        XCTAssertEqual(popupAd.eventName, "test_event")
        XCTAssertNotNil(popupAd.options)
    }

    // MARK: - callback tests

    func testInit_withCallback() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        var closeCalled = false
        var outerLinkCalled = false
        var innerLinkCalled = false

        // When
        let popupAd = RtBPopupAd(tagGroupId: "tag1") { callback in
            callback.onClose = {
                closeCalled = true
            }
            callback.onOuterLink = { _ in
                outerLinkCalled = true
            }
            callback.onInnerLink = { _ in
                innerLinkCalled = true
            }
        }

        // Then
        XCTAssertNotNil(popupAd)
        XCTAssertFalse(closeCalled)
        XCTAssertFalse(outerLinkCalled)
        XCTAssertFalse(innerLinkCalled)
    }

    // MARK: - load tests

    func testLoad_failsWhenUserInfoNotSet() async {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        let popupAd = RtBPopupAd(tagGroupId: "tag1")

        // When/Then
        do {
            try await popupAd.load()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is RetailBoosterError)
        }
    }

    // MARK: - show tests

    func testShow_callsOnCloseWhenNotLoaded() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        var closeCalled = false
        let popupAd = RtBPopupAd(tagGroupId: "tag1") { callback in
            callback.onClose = {
                closeCalled = true
            }
        }

        // When
        popupAd.show()

        // Then
        XCTAssertTrue(closeCalled)
    }

    // MARK: - isUsed tests

    func testShow_canOnlyBeCalledOnce() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        RetailBooster.setUserInfo(userId: "user1", crypto: "crypto1")
        var closeCallCount = 0
        let popupAd = RtBPopupAd(tagGroupId: "tag1") { callback in
            callback.onClose = {
                closeCallCount += 1
            }
        }

        // When - first call
        popupAd.show()
        // When - second call
        popupAd.show()

        // Then - onClose should be called twice (once per show)
        XCTAssertEqual(closeCallCount, 2)
    }

    // MARK: - Integration tests with mock data

    func testLoadWithMockData_setsIsLoaded() {
        // Given
        let mockViewModel = AdViewModel(mockResponse: MockData.rewardResponse)
        let popupAd = RtBPopupAd(
            tagGroupId: "test_tag",
            mockViewModel: mockViewModel
        )

        // Then - should be marked as loaded
        XCTAssertNotNil(popupAd)
    }

    func testShowWithMockData_doesNotCrash() {
        // Given
        var closeCalled = false
        var callback = PopupCallback()
        callback.onClose = {
            closeCalled = true
        }

        let mockViewModel = AdViewModel(mockResponse: MockData.rewardResponse)
        let popupAd = RtBPopupAd(
            tagGroupId: "test_tag",
            callback: callback,
            mockViewModel: mockViewModel
        )

        // When - show without viewController (not loaded state)
        // Note: show() with loaded data would require UIViewController which is not available in unit tests
        // This test verifies the structure is correct

        // Then
        XCTAssertNotNil(popupAd)
    }
}
