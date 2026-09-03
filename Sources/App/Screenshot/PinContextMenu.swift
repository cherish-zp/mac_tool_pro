import AppKit

/// 贴图右键菜单：复制图片 + 关闭贴图。
/// 复制动作把原始全分辨率 CGImage 经注入的 `Pasteboard` 写入剪贴板；
/// 视图不直接触碰 NSPasteboard.general，动作走抽象注入，便于测试。
final class PinContextMenu: NSObject {

    private let pasteboard: Pasteboard
    private let imageProvider: () -> CGImage?
    private let pointSizeProvider: () -> NSSize
    private let closeHandler: () -> Void

    /// pointSizeProvider 提供贴图原始点尺寸（未缩放），复制时携带与工具条一致的 DPI 口径。
    init(pasteboard: Pasteboard,
         imageProvider: @escaping () -> CGImage?,
         pointSizeProvider: @escaping () -> NSSize,
         closeHandler: @escaping () -> Void) {
        self.pasteboard = pasteboard
        self.imageProvider = imageProvider
        self.pointSizeProvider = pointSizeProvider
        self.closeHandler = closeHandler
        super.init()
    }

    /// 构建右键菜单（菜单项 target 为 self；self 由贴图视图持有，菜单弹出期间存活）。
    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        let copyItem = NSMenuItem(title: "复制图片", action: #selector(copyImageToClipboard(_:)), keyEquivalent: "")
        copyItem.target = self
        menu.addItem(copyItem)
        menu.addItem(.separator())
        let closeItem = NSMenuItem(title: "关闭贴图", action: #selector(closePinFromMenu(_:)), keyEquivalent: "")
        closeItem.target = self
        menu.addItem(closeItem)
        return menu
    }

    /// 在视图坐标 point 处弹出菜单。
    func popUp(at point: NSPoint, in view: NSView) {
        makeMenu().popUp(positioning: nil, at: point, in: view)
    }

    @objc private func copyImageToClipboard(_ sender: NSMenuItem) {
        guard let image = imageProvider() else { return }
        let pointSize = pointSizeProvider()
        pasteboard.copyImage(image, pointSize: pointSize)
        DiagLog.write("PinContextMenu: 已复制图片 \(image.width)x\(image.height)（pointSize \(pointSize.width)x\(pointSize.height)）到剪贴板")
    }

    @objc private func closePinFromMenu(_ sender: NSMenuItem) {
        closeHandler()
    }
}
