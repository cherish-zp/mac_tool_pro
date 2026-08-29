import XCTest

/// TDD: 设置窗口布局回归 - 右侧贴图面板必须位于左侧分类栏右侧且不重叠，
/// 分类栏保持 180pt，面板内容不得溢出面板边界。
/// 背景：曾把 arrangedSubview 钉满父视图四边，与 NSSplitView 内部约束冲突，
/// Auto Layout 断链后整窗内容堆叠错乱。
final class SettingsWindowLayoutTests: XCTestCase {

    private func makeLaidOutSplitView() -> NSSplitView {
        let window = SettingsWindow()
        window.contentView?.layoutSubtreeIfNeeded()
        guard let split = window.contentView?.subviews.compactMap({ $0 as? NSSplitView }).first else {
            fatalError("设置窗口内应存在 NSSplitView")
        }
        XCTAssertEqual(split.arrangedSubviews.count, 2, "应有「分类栏 + 详情面板」两个子视图")
        return split
    }

    func test_layout_pinPaneSitsRightOfSidebar() {
        let split = makeLaidOutSplitView()
        let sidebar = split.arrangedSubviews[0]
        let pane = split.arrangedSubviews[1]
        XCTAssertGreaterThanOrEqual(
            pane.frame.minX, sidebar.frame.maxX - 0.5,
            "贴图面板应在分类栏右侧，不得与分类栏重叠（实际 pane.minX=\(pane.frame.minX), sidebar.maxX=\(sidebar.frame.maxX)）"
        )
    }

    func test_layout_sidebarWidthIs180() {
        let split = makeLaidOutSplitView()
        let sidebar = split.arrangedSubviews[0]
        XCTAssertEqual(
            sidebar.frame.width, 180, accuracy: 0.5,
            "分类栏宽度应为 180pt（实际 \(sidebar.frame.width)）"
        )
    }

    func test_layout_paneContentFitsInsidePane() {
        let split = makeLaidOutSplitView()
        let pane = split.arrangedSubviews[1]
        guard let stack = pane.subviews.compactMap({ $0 as? NSStackView }).first else {
            return XCTFail("贴图面板内应有纵向内容栈")
        }
        XCTAssertLessThanOrEqual(
            stack.frame.maxX, pane.bounds.maxX + 0.5,
            "内容栈不得超出面板右边界"
        )
        XCTAssertLessThanOrEqual(
            stack.frame.maxY, pane.bounds.maxY + 0.5,
            "内容栈不得超出面板上边界"
        )
        // AppKit y 轴向上：纵向栈自上而下 = y 递减；相邻视图不得互相重叠
        let views = stack.arrangedSubviews
        for i in 1..<views.count {
            XCTAssertGreaterThanOrEqual(
                views[i - 1].frame.minY, views[i].frame.maxY - 0.5,
                "第 \(i - 1)、\(i) 个设置项在纵向堆叠中重叠"
            )
        }
    }
}
