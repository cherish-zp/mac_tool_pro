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
        XCTAssertEqual(TransferShelfLayoutSpec.hotZoneHeight, 14, accuracy: 0.1)
    }

    func test_dragImageFrameIsNonZero() {
        let frame = TransferShelfLayoutSpec.dragImageFrame
        XCTAssertGreaterThan(frame.width, 0)
        XCTAssertGreaterThan(frame.height, 0)
    }

    func test_dragImageFrameIsSquare() {
        let frame = TransferShelfLayoutSpec.dragImageFrame
        XCTAssertEqual(frame.width, frame.height, accuracy: 0.1)
    }
}
