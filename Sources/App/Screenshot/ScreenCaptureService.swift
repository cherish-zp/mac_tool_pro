import AppKit
import CoreGraphics

/// 截图捕获服务：在显示覆盖层之前抓取各屏幕画面，避免把覆盖层本身截进去。
/// 使用 CoreGraphics CGDisplayCreateImage（macOS 13+ 兼容）。
final class ScreenCaptureService {

    /// 捕获所有活跃显示器，返回 [(显示器ID, 画面, 屏幕Frame)]。
    func captureAllDisplays() -> [(displayID: CGDirectDisplayID, image: CGImage, frame: CGRect)] {
        var maxDisplays: UInt32 = 8
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
        CGGetActiveDisplayList(maxDisplays, &displayIDs, &maxDisplays)

        var results: [(CGDirectDisplayID, CGImage, CGRect)] = []
        for id in displayIDs.prefix(Int(maxDisplays)) {
            guard let image = CGDisplayCreateImage(id) else { continue }
            let bounds = CGDisplayBounds(id)
            results.append((id, image, bounds))
        }
        return results
    }

    /// 请求屏幕录制权限（macOS 10.15+）。首次调用会弹系统授权对话框。
    @discardableResult
    func requestPermission() -> Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess()
        }
        return true
    }
}
