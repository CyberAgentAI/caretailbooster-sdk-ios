import XCTest
@testable import CaRetailBoosterSDK

@available(iOS 13.0, *)
@MainActor
final class RetailBoosterTests: XCTestCase {

    override func setUp() async throws {
        // Reset state before each test
        await RetailBooster.reset()
    }

    override func tearDown() async throws {
        await RetailBooster.reset()
    }

    // MARK: - initialize tests

    func testInitialize_setsConfiguration() {
        // Given
        let mediaId = "test-media-id"
        let mode = RtBRunMode.dev

        // When
        RetailBooster.initialize(mediaId: mediaId, mode: mode)

        // Then
        XCTAssertTrue(RetailBooster.isInitialized)
        XCTAssertNotNil(RetailBooster.currentConfig)
        XCTAssertEqual(RetailBooster.currentConfig?.mediaId, mediaId)
        XCTAssertEqual(RetailBooster.currentConfig?.mode, mode)
    }

    func testInitialize_canBeCalledMultipleTimes() {
        // Given
        RetailBooster.initialize(mediaId: "first", mode: .dev)

        // When
        RetailBooster.initialize(mediaId: "second", mode: .stg)

        // Then
        XCTAssertTrue(RetailBooster.isInitialized)
        XCTAssertEqual(RetailBooster.currentConfig?.mediaId, "second")
        XCTAssertEqual(RetailBooster.currentConfig?.mode, .stg)
    }

    // MARK: - setUserInfo tests

    func testSetUserInfo_updatesConfiguration() {
        // Given
        RetailBooster.initialize(mediaId: "test", mode: .dev)
        let userId = "user123"
        let crypto = "crypto456"

        // When
        RetailBooster.setUserInfo(userId: userId, crypto: crypto)

        // Then
        XCTAssertTrue(RetailBooster.isUserInfoSet)
        XCTAssertEqual(RetailBooster.currentConfig?.userId, userId)
        XCTAssertEqual(RetailBooster.currentConfig?.crypto, crypto)
    }

    func testSetUserInfo_beforeInitialize_doesNotCrash() {
        // When/Then - should not crash
        RetailBooster.setUserInfo(userId: "user", crypto: "crypto")

        XCTAssertFalse(RetailBooster.isUserInfoSet)
    }

    // MARK: - isInitialized tests

    func testIsInitialized_falseByDefault() {
        // Then
        XCTAssertFalse(RetailBooster.isInitialized)
    }

    func testIsInitialized_trueAfterInitialize() {
        // When
        RetailBooster.initialize(mediaId: "test", mode: .dev)

        // Then
        XCTAssertTrue(RetailBooster.isInitialized)
    }

    // MARK: - isUserInfoSet tests

    func testIsUserInfoSet_falseByDefault() {
        // Given
        RetailBooster.initialize(mediaId: "test", mode: .dev)

        // Then
        XCTAssertFalse(RetailBooster.isUserInfoSet)
    }

    func testIsUserInfoSet_trueAfterSetUserInfo() {
        // Given
        RetailBooster.initialize(mediaId: "test", mode: .dev)

        // When
        RetailBooster.setUserInfo(userId: "user", crypto: "crypto")

        // Then
        XCTAssertTrue(RetailBooster.isUserInfoSet)
    }
}
