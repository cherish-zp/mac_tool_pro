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

    // MARK: - 超时安全网（覆盖层未显示时会话卡死防护）

    func test_isTimedOut_immediatelyAfterStart_isFalse() {
        let session = ScreenshotSession()
        let now = Date()
        _ = session.start(at: now)
        XCTAssertFalse(session.isTimedOut(now: now))
    }

    func test_isTimedOut_afterInterval_isTrue() {
        let session = ScreenshotSession()
        let start = Date()
        _ = session.start(at: start)
        let later = start.addingTimeInterval(session.timeoutInterval + 1)
        XCTAssertTrue(session.isTimedOut(now: later))
    }

    func test_isTimedOut_beforeInterval_isFalse() {
        let session = ScreenshotSession()
        let start = Date()
        _ = session.start(at: start)
        let later = start.addingTimeInterval(session.timeoutInterval - 1)
        XCTAssertFalse(session.isTimedOut(now: later))
    }

    func test_isTimedOut_afterFinish_isFalse() {
        let session = ScreenshotSession()
        let start = Date()
        _ = session.start(at: start)
        session.finish()
        let later = start.addingTimeInterval(session.timeoutInterval + 10)
        XCTAssertFalse(session.isTimedOut(now: later))
    }
