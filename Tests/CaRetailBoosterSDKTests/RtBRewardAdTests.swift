import XCTest
@testable import CaRetailBoosterSDK

@available(iOS 13.0, *)
@MainActor
final class RtBRewardAdTests: XCTestCase {

    override func setUp() async throws {
        await RetailBooster.reset()
    }

    override func tearDown() async throws {
        await RetailBooster.reset()
    }

    // MARK: - init tests

    func testInit_failsWhenSDKNotInitialized() {
        // When
        let rewardAd = RtBRewardAd(tagGroupId: "tag1")

        // Then
        XCTAssertNil(rewardAd)
    }

    func testInit_succeedsWhenSDKInitialized() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)

        // When
        let rewardAd = RtBRewardAd(tagGroupId: "tag1")

        // Then
        XCTAssertNotNil(rewardAd)
        XCTAssertEqual(rewardAd?.tagGroupId, "tag1")
    }

    func testInit_withEventNameAndOptions() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        let options = RewardOptions(
            size: SizeOption(width: 173, height: 210),
            itemSpacing: 16,
            leadingMargin: 16,
            trailingMargin: 16
        )

        // When
        let rewardAd = RtBRewardAd(
            tagGroupId: "tag1",
            eventName: "test_event",
            options: options
        )

        // Then
        XCTAssertNotNil(rewardAd)
        XCTAssertEqual(rewardAd?.tagGroupId, "tag1")
        XCTAssertEqual(rewardAd?.eventName, "test_event")
        XCTAssertNotNil(rewardAd?.options)
    }

    // MARK: - callback tests

    func testInit_withCallback() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        var markSucceededCalled = false
        var modalClosedCalled = false

        // When
        let rewardAd = RtBRewardAd(tagGroupId: "tag1") { callback in
            callback.onMarkSucceeded = {
                markSucceededCalled = true
            }
            callback.onRewardModalClosed = {
                modalClosedCalled = true
            }
        }

        // Then
        XCTAssertNotNil(rewardAd)
        XCTAssertFalse(markSucceededCalled)
        XCTAssertFalse(modalClosedCalled)
    }

    // MARK: - load tests

    func testLoad_failsWhenUserInfoNotSet() async {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        let rewardAd = RtBRewardAd(tagGroupId: "tag1")

        // When/Then
        do {
            try await rewardAd?.load()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is RetailBoosterError)
        }
    }

    // MARK: - views tests

    func testViews_emptyBeforeLoad() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        let rewardAd = RtBRewardAd(tagGroupId: "tag1")

        // When
        let views = rewardAd?.views ?? []

        // Then
        XCTAssertTrue(views.isEmpty)
    }

    // MARK: - areaName/areaDescription tests

    func testAreaName_nilBeforeLoad() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        let rewardAd = RtBRewardAd(tagGroupId: "tag1")

        // When
        let areaName = rewardAd?.areaName

        // Then
        XCTAssertNil(areaName)
    }

    func testAreaDescription_nilBeforeLoad() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        let rewardAd = RtBRewardAd(tagGroupId: "tag1")

        // When
        let areaDescription = rewardAd?.areaDescription

        // Then
        XCTAssertNil(areaDescription)
    }

    // MARK: - Integration tests with mock data

    func testLoadWithMockData_populatesViewModel() {
        // Given
        let mockViewModel = AdViewModel(mockResponse: MockData.rewardResponse)
        let rewardAd = RtBRewardAd(
            tagGroupId: "test_tag",
            mockViewModel: mockViewModel
        )

        // Then
        XCTAssertEqual(rewardAd.areaName, "おすすめエリア")
        XCTAssertEqual(rewardAd.areaDescription, "あなたにおすすめの広告")
    }

    func testViewsWithMockData_returnsNonEmptyViews() {
        // Given
        let mockViewModel = AdViewModel(mockResponse: MockData.rewardResponse)
        let rewardAd = RtBRewardAd(
            tagGroupId: "test_tag",
            mockViewModel: mockViewModel
        )

        // When
        let views = rewardAd.views

        // Then
        XCTAssertEqual(views.count, 3)
    }

    func testViewsWithMockData_emptyWhenNoAds() {
        // Given
        let mockViewModel = AdViewModel(mockResponse: MockData.emptyResponse)
        let rewardAd = RtBRewardAd(
            tagGroupId: "test_tag",
            mockViewModel: mockViewModel
        )

        // When
        let views = rewardAd.views

        // Then
        XCTAssertTrue(views.isEmpty)
    }
}
