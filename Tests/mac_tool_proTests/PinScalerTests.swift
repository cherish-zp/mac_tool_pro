import XCTest
import CoreGraphics

/// TDD: 贴图等比例缩放器 - 计算缩放后尺寸、限制范围、保持中心。
final class PinScalerTests: XCTestCase {

    func test_scaledSize_preservesAspectRatio() {
        let original = CGSize(width: 200, height: 100)
        let scaled = PinScaler.scaledSize(original: original, scaleFactor: 1.5)
        XCTAssertEqual(scaled.width, 300, accuracy: 0.001)
        XCTAssertEqual(scaled.height, 150, accuracy: 0.001)
    }

    func test_scaledSize_scaleDown() {
        let original = CGSize(width: 200, height: 100)
        let scaled = PinScaler.scaledSize(original: original, scaleFactor: 0.5)
        XCTAssertEqual(scaled.width, 100, accuracy: 0.001)
        XCTAssertEqual(scaled.height, 50, accuracy: 0.001)
    }

    func test_clampedScaleFactor_respectsMax() {
        XCTAssertEqual(PinScaler.clampedScaleFactor(10.0), PinScaler.maxScale)
    }

    func test_clampedScaleFactor_respectsMin() {
        XCTAssertEqual(PinScaler.clampedScaleFactor(0.01), PinScaler.minScale)
    }

    func test_scaledSize_doesNotExceedMax() {
        let original = CGSize(width: 200, height: 100)
        let scaled = PinScaler.scaledSize(original: original, scaleFactor: 100)
        XCTAssertEqual(scaled.width, 200 * PinScaler.maxScale, accuracy: 0.001)
    }

    func test_scaledSize_doesNotGoBelowMin() {
        let original = CGSize(width: 200, height: 100)
        let scaled = PinScaler.scaledSize(original: original, scaleFactor: 0.001)
        XCTAssertEqual(scaled.width, 200 * PinScaler.minScale, accuracy: 0.001)
    }

    func test_scaledFrame_keepsCenter() {
        let frame = CGRect(x: 100, y: 200, width: 200, height: 100)
        let newSize = CGSize(width: 300, height: 150)
        let result = PinScaler.scaledFrame(originalFrame: frame, newSize: newSize)
        XCTAssertEqual(result.midX, frame.midX, accuracy: 0.001)
        XCTAssertEqual(result.midY, frame.midY, accuracy: 0.001)
        XCTAssertEqual(result.width, 300, accuracy: 0.001)
        XCTAssertEqual(result.height, 150, accuracy: 0.001)
    }


    // MARK: - 关闭按钮等比例缩放

    func test_scaledButtonSize_proportional() {
        XCTAssertEqual(PinScaler.scaledButtonSize(scaleFactor: 2.0), 44, accuracy: 0.001)
        XCTAssertEqual(PinScaler.scaledButtonSize(scaleFactor: 0.75), 16.5, accuracy: 0.001)
    }

    func test_scaledButtonSize_clampedMin() {
        let result = PinScaler.scaledButtonSize(scaleFactor: 0.1)
        XCTAssertEqual(result, PinScaler.minButtonSize, accuracy: 0.001)
    }

    func test_scaledButtonSize_clampedMax() {
        let result = PinScaler.scaledButtonSize(scaleFactor: 10.0)
        XCTAssertEqual(result, PinScaler.maxButtonSize, accuracy: 0.001)
    }

    func test_scaledButtonFrame_topLeftPosition() {
        // isFlipped=false，左上角 = (margin*s, height - margin*s - size)
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 200)
        let frame = PinScaler.scaledButtonFrame(viewBounds: bounds, scaleFactor: 2.0)
        let expectedSize: CGFloat = 44  // 22*2
        let expectedMargin: CGFloat = 8  // 4*2
        XCTAssertEqual(frame.width, expectedSize, accuracy: 0.001)
        XCTAssertEqual(frame.height, expectedSize, accuracy: 0.001)
        XCTAssertEqual(frame.origin.x, expectedMargin, accuracy: 0.001)
        XCTAssertEqual(frame.origin.y, bounds.height - expectedMargin - expectedSize, accuracy: 0.001)
    }

    // MARK: - 悬停浮现按钮（topBar 模式，尺寸减半）

    func test_scaledRevealButtonSize_isHalfOfRegularButtonSize() {
        XCTAssertEqual(PinScaler.scaledRevealButtonSize(scaleFactor: 1.0), 11, accuracy: 0.001)
        XCTAssertEqual(PinScaler.scaledRevealButtonSize(scaleFactor: 2.0), 22, accuracy: 0.001)
        XCTAssertEqual(PinScaler.scaledRevealButtonSize(scaleFactor: 0.75), 8.25, accuracy: 0.001)
    }

    func test_scaledRevealButtonSize_clampedMin() {
        XCTAssertEqual(PinScaler.minRevealButtonSize, 8, accuracy: 0.001)
        XCTAssertEqual(PinScaler.scaledRevealButtonSize(scaleFactor: 0.5), PinScaler.minRevealButtonSize, accuracy: 0.001)
    }

    func test_scaledRevealButtonSize_clampedMax() {
        XCTAssertEqual(PinScaler.maxRevealButtonSize, 30, accuracy: 0.001)
        XCTAssertEqual(PinScaler.scaledRevealButtonSize(scaleFactor: 10.0), PinScaler.maxRevealButtonSize, accuracy: 0.001)
    }

    func test_scaledRevealButtonFrame_topLeftPosition() {
        // isFlipped=false，左上角 = (margin*s, height - margin*s - size)，定位逻辑与常规按钮一致
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 200)
        let frame = PinScaler.scaledRevealButtonFrame(viewBounds: bounds, scaleFactor: 2.0)
        XCTAssertEqual(frame.width, 22, accuracy: 0.001)   // 11*2
        XCTAssertEqual(frame.height, 22, accuracy: 0.001)
        XCTAssertEqual(frame.origin.x, 8, accuracy: 0.001) // 4*2
        XCTAssertEqual(frame.origin.y, bounds.height - 8 - 22, accuracy: 0.001)
    }

}