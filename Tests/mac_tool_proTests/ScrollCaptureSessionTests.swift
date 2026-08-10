import XCTest
import CoreGraphics
import AppKit

/// TDD: 滚动截图会话状态机 - ready/capturing/done + auto/manual 模式。
final class ScrollCaptureSessionTests: XCTestCase {

    // MARK: - 初始状态

    func test_initialState_isReady() {
        let session = ScrollCaptureSession(maxFrames: 30)
        XCTAssertEqual(session.state, .ready)
        XCTAssertNil(session.mode)
        XCTAssertEqual(session.count, 0)
    }

    // MARK: - 模式启动

    func test_startAuto_setsCapturingAndAutoMode() {
        var session = ScrollCaptureSession(maxFrames: 30)
        session.startAuto()
        XCTAssertEqual(session.state, .capturing)
        XCTAssertEqual(session.mode, .auto)
    }

    func test_startManual_setsCapturingAndManualMode() {
        var session = ScrollCaptureSession(maxFrames: 30)
        session.startManual()
        XCTAssertEqual(session.state, .capturing)
        XCTAssertEqual(session.mode, .manual)
    }

    func test_startAuto_whenAlreadyCapturing_doesNothing() {
        var session = ScrollCaptureSession(maxFrames: 30)
        session.startManual()
        session.startAuto()
        XCTAssertEqual(session.mode, .manual)
    }

    // MARK: - 截帧

    func test_tryAdd_inReadyState_returnsFalse() {
        var session = ScrollCaptureSession(maxFrames: 30)
        XCTAssertFalse(session.tryAdd(makeImage(red: 1.0)))
        XCTAssertEqual(session.count, 0)
    }

    func test_tryAdd_firstFrameInCapturing_alwaysAdded() {
        var session = ScrollCaptureSession(maxFrames: 5)
        session.startManual()
        XCTAssertTrue(session.tryAdd(makeImage(red: 1.0)))
        XCTAssertEqual(session.count, 1)
    }

    func test_tryAdd_identicalFrameNotAdded() {
        var session = ScrollCaptureSession(maxFrames: 5)
        session.startManual()
        let frame = makeImage(red: 0.33)
        session.tryAdd(frame)
        XCTAssertFalse(session.tryAdd(frame))
        XCTAssertEqual(session.count, 1)
    }

    func test_tryAdd_changedFrameAdded() {
        var session = ScrollCaptureSession(maxFrames: 5)
        session.startManual()
        session.tryAdd(makeImage(red: 1.0))
        XCTAssertTrue(session.tryAdd(makeImage(red: 0.66)))
        XCTAssertEqual(session.count, 2)
    }

    func test_tryAdd_maxFramesSetsDone() {
        var session = ScrollCaptureSession(maxFrames: 3)
        session.startAuto()
        session.tryAdd(makeImage(red: 1.0))
        session.tryAdd(makeImage(red: 0.66))
        session.tryAdd(makeImage(red: 0.33))
        XCTAssertEqual(session.count, 3)
        XCTAssertEqual(session.state, .done)
        XCTAssertFalse(session.tryAdd(makeImage(red: 0.15)))
    }

    // MARK: - 停止

    func test_stop_setsDone() {
        var session = ScrollCaptureSession(maxFrames: 5)
        session.startManual()
        session.tryAdd(makeImage(red: 1.0))
        session.stop()
        XCTAssertEqual(session.state, .done)
        XCTAssertFalse(session.tryAdd(makeImage(red: 0.5)))
    }

    func test_stop_whenReady_setsDone() {
        var session = ScrollCaptureSession(maxFrames: 5)
        session.stop()
        XCTAssertEqual(session.state, .done)
    }

    // MARK: - 坐标转换

    func test_displayCaptureRect_flipsY() {
        let viewRect = CGRect(x: 100, y: 200, width: 300, height: 400)
        let display = ScrollCaptureSession.displayCaptureRect(viewRect: viewRect, screenHeight: 1080)
        XCTAssertEqual(display.origin.x, 100, accuracy: 0.001)
        XCTAssertEqual(display.origin.y, 480, accuracy: 0.001)
        XCTAssertEqual(display.width, 300, accuracy: 0.001)
        XCTAssertEqual(display.height, 400, accuracy: 0.001)
    }

    func test_globalCaptureRect_singleDisplay() {
        let displayRect = CGRect(x: 100, y: 200, width: 300, height: 400)
        let displayBounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let global = ScrollCaptureSession.globalCaptureRect(displayRect: displayRect, displayBounds: displayBounds)
        XCTAssertEqual(global.origin.x, 100, accuracy: 0.001)
        XCTAssertEqual(global.origin.y, 200, accuracy: 0.001)
    }

    func test_globalCaptureRect_multiDisplay() {
        let displayRect = CGRect(x: 100, y: 200, width: 300, height: 400)
        let displayBounds = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
        let global = ScrollCaptureSession.globalCaptureRect(displayRect: displayRect, displayBounds: displayBounds)
        XCTAssertEqual(global.origin.x, -1820, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func makeImage(red: CGFloat, width: Int = 40, height: Int = 40) -> CGImage {
        let cs = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(data: nil, width: width, height: height,
                            bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(NSColor(srgbRed: red, green: 0, blue: 0, alpha: 1).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage()!
    }


    // MARK: - 自动滚动方向

    func test_autoScrollDelta_isNegative_forDownwardScroll() {
        // 长截图应向下滚动（内容上移、新内容出现在底部），
        // CGEvent wheel1 负值 = 向下滚动
        XCTAssertLessThan(ScrollCaptureSession.autoScrollDelta, 0,
                          "自动滚动 delta 应为负值（向下滚动）")
    }

}