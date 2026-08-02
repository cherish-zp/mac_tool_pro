import XCTest

/// TDD: 截图会话状态管理 - 防止重复触发、正确重置状态。
final class ScreenshotSessionTests: XCTestCase {

    func test_initialState_isIdle() {
        let session = ScreenshotSession()
        XCTAssertEqual(session.state, .idle)
    }

    func test_start_whenIdle_returnsTrue() {
        let session = ScreenshotSession()
        XCTAssertTrue(session.start())
        XCTAssertEqual(session.state, .active)
    }

    func test_start_whenActive_returnsFalse() {
        let session = ScreenshotSession()
        XCTAssertTrue(session.start())
        XCTAssertFalse(session.start(), "已活跃时不应允许再次启动")
        XCTAssertEqual(session.state, .active)
    }

    func test_finish_resetsToIdle() {
        let session = ScreenshotSession()
        _ = session.start()
        session.finish()
        XCTAssertEqual(session.state, .idle)
    }

    func test_finish_thenStart_againWorks() {
        let session = ScreenshotSession()
        _ = session.start()
        session.finish()
        XCTAssertTrue(session.start(), "结束后应能再次启动")
    }

    func test_escKeyCode_is53() {
        XCTAssertEqual(ScreenshotSession.escKeyCode, 53)
    }
}
