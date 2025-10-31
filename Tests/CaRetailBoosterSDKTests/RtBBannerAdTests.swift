import XCTest
@testable import CaRetailBoosterSDK

@available(iOS 13.0, *)
@MainActor
final class RtBBannerAdTests: XCTestCase {

    override func setUp() async throws {
        await RetailBooster.reset()
    }

    override func tearDown() async throws {
        await RetailBooster.reset()
    }

    // MARK: - init tests

    func testInit_succeededEvenWhenSDKNotInitialized() {
        // When
        let bannerAd = RtBBannerAd(tagGroupId: "tag1")

        // Then
        XCTAssertNotNil(bannerAd)
        XCTAssertEqual(bannerAd.tagGroupId, "tag1")
    }

    func testInit_succeedsWhenSDKInitialized() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)

        // When
        let bannerAd = RtBBannerAd(tagGroupId: "tag1")

        // Then
        XCTAssertNotNil(bannerAd)
        XCTAssertEqual(bannerAd.tagGroupId, "tag1")
    }

    func testInit_withEventNameAndOptions() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        let options = BannerOptions(size: SizeOption(width: 320, height: 50))

        // When
        let bannerAd = RtBBannerAd(
            tagGroupId: "tag1",
            eventName: "test_event",
            options: options
        )

        // Then
        XCTAssertNotNil(bannerAd)
        XCTAssertEqual(bannerAd.tagGroupId, "tag1")
        XCTAssertEqual(bannerAd.eventName, "test_event")
        XCTAssertNotNil(bannerAd.options)
    }

    // MARK: - load tests

    func testLoad_failsWhenUserInfoNotSet() async {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        let bannerAd = RtBBannerAd(tagGroupId: "tag1")

        // When/Then
        do {
            try await bannerAd.load()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is RetailBoosterError)
        }
    }

    // MARK: - views tests

    func testViews_emptyBeforeLoad() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        let bannerAd = RtBBannerAd(tagGroupId: "tag1")

        // When
        let views = bannerAd.views

        // Then
        XCTAssertTrue(views.isEmpty)
    }

    // MARK: - areaName/areaDescription tests

    func testAreaName_nilBeforeLoad() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        let bannerAd = RtBBannerAd(tagGroupId: "tag1")

        // When
        let areaName = bannerAd.areaName

        // Then
        XCTAssertNil(areaName)
    }

    func testAreaDescription_nilBeforeLoad() {
        // Given
        RetailBooster.initialize(mediaId: "media1", mode: .dev)
        let bannerAd = RtBBannerAd(tagGroupId: "tag1")

        // When
        let areaDescription = bannerAd.areaDescription

        // Then
        XCTAssertNil(areaDescription)
    }

    // MARK: - Integration tests with mock data

    func testLoadWithMockData_populatesViewModel() {
        // Given
        let mockViewModel = AdViewModel(mockResponse: MockData.bannerResponse)
        let bannerAd = RtBBannerAd(
            tagGroupId: "test_tag",
            mockViewModel: mockViewModel
        )

        // Then
        XCTAssertEqual(bannerAd.areaName, "おすすめエリア")
        XCTAssertEqual(bannerAd.areaDescription, "あなたにおすすめの広告")
    }

    func testViewsWithMockData_returnsNonEmptyViews() {
        // Given
        let mockViewModel = AdViewModel(mockResponse: MockData.bannerResponse)
        let bannerAd = RtBBannerAd(
            tagGroupId: "test_tag",
            mockViewModel: mockViewModel
        )

        // When
        let views = bannerAd.views

        // Then
        XCTAssertEqual(views.count, 2)
    }

    func testViewsWithMockData_emptyWhenNoAds() {
        // Given
        let mockViewModel = AdViewModel(mockResponse: MockData.emptyResponse)
        let bannerAd = RtBBannerAd(
            tagGroupId: "test_tag",
            mockViewModel: mockViewModel
        )

        // When
        let views = bannerAd.views

        // Then
        XCTAssertTrue(views.isEmpty)
    }

    // MARK: - Error filtering tests

    func testViewsWithError_excludesErrorAds() {
        // Given
        let mockViewModel = AdViewModel(mockResponse: MockData.bannerResponse)
        let bannerAd = RtBBannerAd(
            tagGroupId: "test_tag",
            mockViewModel: mockViewModel
        )

        // When: Mark first banner ad as having an error
        mockViewModel.markBannerAdAsError(adId: 2001)
        let views = bannerAd.views

        // Then: Only one view should be returned (the second banner without error)
        XCTAssertEqual(views.count, 1)
    }

    func testViewsWithError_excludesAllErrorAds() {
        // Given
        let mockViewModel = AdViewModel(mockResponse: MockData.bannerResponse)
        let bannerAd = RtBBannerAd(
            tagGroupId: "test_tag",
            mockViewModel: mockViewModel
        )

        // When: Mark all banner ads as having errors
        mockViewModel.markBannerAdAsError(adId: 2001)
        mockViewModel.markBannerAdAsError(adId: 2002)
        let views = bannerAd.views

        // Then: No views should be returned
        XCTAssertTrue(views.isEmpty)
    }

    func testViewsWithError_returnsAllWhenNoErrors() {
        // Given
        let mockViewModel = AdViewModel(mockResponse: MockData.bannerResponse)
        let bannerAd = RtBBannerAd(
            tagGroupId: "test_tag",
            mockViewModel: mockViewModel
        )

        // When: No errors are marked
        let views = bannerAd.views

        // Then: All views should be returned
        XCTAssertEqual(views.count, 2)
    }
}
