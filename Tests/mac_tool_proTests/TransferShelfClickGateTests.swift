import XCTest

/// TransferShelfClickGate 区分条目上的「单击」与「拖出」手势。
/// 修复的 bug:此前在 mouseDown(按下)时立即弹出 Finder 定位窗口,
/// 系统还没来得及判定这是拖拽,弹出窗口抢走焦点、掐断了拖出到
/// 目标目录的手势。规则应为:按下只做记录,松开时若未进入拖拽才算单击。
final class TransferShelfClickGateTests: XCTestCase {

    func test_pressWithoutDrag_isClick() {
        var gate = TransferShelfClickGate()
        gate.press()
        XCTAssertTrue(gate.isClick, "按下后未拖拽,松开应视为单击")
    }

    func test_dragSuppressesClick() {
        var gate = TransferShelfClickGate()
        gate.press()
        gate.beginDrag()
        XCTAssertFalse(gate.isClick, "拖拽开始后,松开不得再触发单击动作")
    }

    func test_newPressResetsDragState() {
        var gate = TransferShelfClickGate()
        gate.press()
        gate.beginDrag()
        gate.press()
        XCTAssertTrue(gate.isClick, "新的一次按下应重置判定,不影响下一次单击")
    }

    func test_initialState_isNotClick() {
        let gate = TransferShelfClickGate()
        XCTAssertFalse(gate.isClick, "未按下时不应触发单击动作(松开事件可能早于按下抵达)")
    }
}
