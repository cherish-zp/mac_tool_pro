import XCTest

/// TDD: 快速片段复制成功 Toast 规格 - 苹果风淡入淡出 HUD。
final class CopyToastSpecTests: XCTestCase {

    func test_successMessage() {
        XCTAssertEqual(CopyToastSpec.successMessage, "已复制")
    }

    func test_symbolName() {
        XCTAssertEqual(CopyToastSpec.symbolName, "checkmark.circle.fill")
    }

    func test_fadeInDurationIsShort() {
        XCTAssertEqual(CopyToastSpec.fadeInDuration, 0.18, accuracy: 0.001)
    }

    func test_visibleDuration() {
        XCTAssertEqual(CopyToastSpec.visibleDuration, 1.2, accuracy: 0.001)
    }

    func test_fadeOutDurationIsSmooth() {
        XCTAssertEqual(CopyToastSpec.fadeOutDuration, 0.28, accuracy: 0.001)
    }

    func test_totalDurationSumsPhases() {
        XCTAssertEqual(
            CopyToastSpec.totalDuration,
            CopyToastSpec.fadeInDuration + CopyToastSpec.visibleDuration + CopyToastSpec.fadeOutDuration,
            accuracy: 0.001
        )
    }

    func test_cornerRadius() {
        XCTAssertEqual(CopyToastSpec.cornerRadius, 14, accuracy: 0.1)
    }

    func test_topGapBelowMenuBar() {
        XCTAssertEqual(CopyToastSpec.topGap, 8, accuracy: 0.1)
    }
}
