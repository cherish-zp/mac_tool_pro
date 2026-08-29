import AppKit

/// 贴图右键菜单：在贴图任意位置右键弹出「复制图片」，
/// 点击后把原始全分辨率 CGImage 经注入的 `Pasteboard` 写入剪贴板。
/// 视图不直接触碰 NSPasteboard.general，复制动作走 Pasteboard 抽象，便于注入测试。
final class PinContextMenu: NSObject {

    private let pasteboard: Pasteboard
    private let imageProvider: () -> CGImage?

    init(pasteboard: Pasteboard, imageProvider: @escaping () -> CGImage?) {
        self.pasteboard = pasteboard
        self.imageProvider = imageProvider
        super.init()
    }

    /// 构建右键菜单（菜单项 target 为 self；self 由贴图视图持有，菜单弹出期间存活）。
    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        let item = NSMenuItem(title: "复制图片", action: #selector(copyImageToClipboard(_:)), keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return menu
    }

    /// 在视图坐标 point 处弹出菜单。
    func popUp(at point: NSPoint, in view: NSView) {
        makeMenu().popUp(positioning: nil, at: point, in: view)
    }

    @objc private func copyImageToClipboard(_ sender: NSMenuItem) {
        guard let image = imageProvider() else { return }
        pasteboard.copyImage(image)
        DiagLog.write("PinContextMenu: 已复制图片 \(image.width)x\(image.height) 到剪贴板")
    }
}
