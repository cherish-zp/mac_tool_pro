import Foundation

/// 区分文件中转站条目上的「单击」与「拖出」两种手势。
///
/// mouseDown 早于系统对两种手势的判定:若在按下时立即执行单击动作
/// (弹出 Finder 定位窗口),窗口会抢走焦点并掐断随后开始的拖拽,
/// 用户无法把文件拖到目标目录。ClickGate 把单击动作推迟到松开时:
/// 按下只做记录,一旦拖拽会话开始,本次按住期间不再算作单击。
struct TransferShelfClickGate {
    private var pressed = false
    private(set) var dragBegan = false

    /// 每次按下重置手势判定。
    mutating func press() {
        pressed = true
        dragBegan = false
    }

    /// 拖拽会话已开始:本次按住标记为拖拽手势。
    mutating func beginDrag() {
        dragBegan = true
    }

    /// 松开时是否应执行单击动作(仅当确实按过且未进入拖拽)。
    var isClick: Bool { pressed && !dragBegan }
}
