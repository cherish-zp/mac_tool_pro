import XCTest

/// TDD: 文件中转站布局规格 - 顶部横向面板、条目尺寸、动画参数。
final class TransferShelfLayoutSpecTests: XCTestCase {

    func test_panelHeight() {
        XCTAssertEqual(TransferShelfLayoutSpec.panelHeight, 68, accuracy: 0.1)
    }

    func test_itemSize() {
        XCTAssertEqual(TransferShelfLayoutSpec.itemSize, 52, accuracy: 0.1)
    }

    func test_itemSpacing() {
        XCTAssertEqual(TransferShelfLayoutSpec.itemSpacing, 10, accuracy: 0.1)
    }

    func test_cornerRadius() {
        XCTAssertEqual(TransferShelfLayoutSpec.cornerRadius, 20, accuracy: 0.1)
    }

    func test_panelWidthFitsItems() {
        let width = TransferShelfLayoutSpec.panelWidth(itemCount: 3)
        let expected: CGFloat = 12 + 52 * 3 + 10 * 2 + 12
        XCTAssertEqual(width, expected, accuracy: 0.1)
    }

    func test_panelWidthCappedToMax() {
        let width = TransferShelfLayoutSpec.panelWidth(itemCount: 30, maxWidth: 400)
        XCTAssertLessThanOrEqual(width, 400)
    }

    func test_fadeDurations() {
        XCTAssertEqual(TransferShelfLayoutSpec.fadeInDuration, 0.2, accuracy: 0.001)
        XCTAssertEqual(TransferShelfLayoutSpec.fadeOutDuration, 0.25, accuracy: 0.001)
    }

    func test_topGap() {
        XCTAssertEqual(TransferShelfLayoutSpec.topGap, 4, accuracy: 0.1)
    }

    func test_slideInOffset() {
        XCTAssertEqual(TransferShelfLayoutSpec.slideInOffset, 12, accuracy: 0.1)
    }

    func test_hotZoneSize() {
        XCTAssertEqual(TransferShelfLayoutSpec.hotZoneWidth, 320, accuracy: 0.1)
        XCTAssertEqual(TransferShelfLayoutSpec.hotZoneHeight, 18, accuracy: 0.1)
    }

    func test_hotZoneHitTopCenter() {
        let frame = NSRect(x: 0, y: 0, width: 1000, height: 800)
        let point = NSPoint(x: 500, y: 795)
        XCTAssertTrue(TransferShelfLayoutSpec.isInHotZone(location: point, visibleFrame: frame))
    }

    func test_hotZoneMissTopLeft() {
        let frame = NSRect(x: 0, y: 0, width: 1000, height: 800)
        let point = NSPoint(x: 50, y: 795)
        XCTAssertFalse(TransferShelfLayoutSpec.isInHotZone(location: point, visibleFrame: frame))
    }

    func test_hotZoneMissMiddle() {
        let frame = NSRect(x: 0, y: 0, width: 1000, height: 800)
        let point = NSPoint(x: 500, y: 400)
        XCTAssertFalse(TransferShelfLayoutSpec.isInHotZone(location: point, visibleFrame: frame))
    }

    func test_hotZoneHitRespectsVisibleFrameOrigin() {
        let frame = NSRect(x: 100, y: 50, width: 1000, height: 800)
        let point = NSPoint(x: 600, y: 845)
        XCTAssertTrue(TransferShelfLayoutSpec.isInHotZone(location: point, visibleFrame: frame))
    }

    func test_dragImageFrameIsNonZero() {
        let frame = TransferShelfLayoutSpec.dragImageFrame
        XCTAssertGreaterThan(frame.width, 0)
        XCTAssertGreaterThan(frame.height, 0)
    }

    func test_verticalPanelWidth() {
        XCTAssertEqual(TransferShelfLayoutSpec.verticalPanelWidth, 76, accuracy: 0.1)
    }

    func test_verticalPanelHeightFitsItems() {
        let height = TransferShelfLayoutSpec.panelHeight(itemCount: 3)
        let expected: CGFloat = 12 + 52 * 3 + 10 * 2 + 12
        XCTAssertEqual(height, expected, accuracy: 0.1)
    }

    func test_verticalPanelHeightCappedToMax() {
        let height = TransferShelfLayoutSpec.panelHeight(itemCount: 30, maxHeight: 400)
        XCTAssertLessThanOrEqual(height, 400)
    }

    func test_panelBackgroundAlpha() {
        XCTAssertEqual(TransferShelfLayoutSpec.panelBackgroundAlpha, 0.82, accuracy: 0.001)
    }

    func test_panelHairlineWidth() {
        XCTAssertEqual(TransferShelfLayoutSpec.panelHairlineWidth, 1, accuracy: 0.1)
    }

    func test_itemCornerRadius() {
        XCTAssertEqual(TransferShelfLayoutSpec.itemCornerRadius, 12, accuracy: 0.1)
    }

    func test_itemClearButtonSize() {
        XCTAssertEqual(TransferShelfLayoutSpec.itemClearButtonSize, 12, accuracy: 0.1)
    }

    func test_itemClearButtonInsets() {
        XCTAssertEqual(TransferShelfLayoutSpec.itemClearButtonOffset, 2, accuracy: 0.1)
    }

    func test_dragImageFrameIsSquare() {
        let frame = TransferShelfLayoutSpec.dragImageFrame
        XCTAssertEqual(frame.width, frame.height, accuracy: 0.1)
    }
}
