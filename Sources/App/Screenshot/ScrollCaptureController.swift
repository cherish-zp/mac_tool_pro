import AppKit
import CoreGraphics

/// 滚动截图控制器：管理截帧、去重、拼接。
/// 支持自动/手动两种滚动模式，由 ScrollCaptureSession 状态机驱动。
final class ScrollCaptureController {

    private let config = ScreenshotConfig()
    private var session = ScrollCaptureSession(maxFrames: 30)
    private let displayID: CGDirectDisplayID
    private let captureRect: CGRect
    private let scaleFactor: CGFloat
    /// 截帧时要排除的窗口 ID（选区边框窗口）。
    var excludeWindowID: CGWindowID?

    init(displayID: CGDirectDisplayID, captureRect: CGRect, scaleFactor: CGFloat) {
        self.displayID = displayID
        self.captureRect = captureRect
        self.scaleFactor = scaleFactor
    }

    var frameCount: Int { session.count }
    var state: ScrollCaptureSession.State { session.state }
    var mode: ScrollCaptureSession.Mode? { session.mode }
    var isDone: Bool { session.isDone }

    /// 开始自动滚动截取。
    func startAuto() { session.startAuto() }

    /// 开始手动滚动截取（鼠标滚动触发）。
    func startManual() { session.startManual() }

    /// 停止截取。
    func stop() { session.stop() }

    /// 截取当前选区帧，内容变化时加入序列。返回是否实际加入。
    @discardableResult
    func captureFrame() -> Bool {
        let frame: CGImage?
        if let excludeID = excludeWindowID {
            let bounds = CGDisplayBounds(displayID)
            let globalRect = ScrollCaptureSession.globalCaptureRect(
                displayRect: captureRect, displayBounds: bounds)
            frame = CGWindowListCreateImage(globalRect, .optionOnScreenBelowWindow, excludeID, [.bestResolution])
        } else {
            frame = CGDisplayCreateImage(displayID, rect: captureRect)
        }
        guard let img = frame else { return false }
        return session.tryAdd(img)
    }

    /// 拼接所有帧为长图（纯拼接，无副作用）。
    func stitch() -> NSImage? {
        guard !session.frames.isEmpty else { return nil }
        let stitched: CGImage?
        if session.frames.count > 1 {
            stitched = ScrollStitcher.stitch(images: session.frames)
        } else {
            stitched = session.frames.first
        }
        guard let result = stitched else { return nil }
        let displaySize = SelectionRect.pointSize(
            pixelSize: CGSize(width: result.width, height: result.height),
            scaleFactor: scaleFactor
        )
        return NSImage(cgImage: result, size: displaySize)
    }

    /// 保存图片到文件。
    func saveToFile(image: NSImage) {
        let dir = config.saveDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let existing = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        let name = ScreenshotFileNameBuilder.uniqueFileName(
            date: Date(), config: config, existingNames: Set(existing)
        )
        let url = dir.appendingPathComponent(name)
        if let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff) {
            let data = rep.representation(using: .png, properties: [:])
            try? data?.write(to: url)
        }
    }
}
