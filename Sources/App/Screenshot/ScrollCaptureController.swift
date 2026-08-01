import AppKit
import CoreGraphics

/// 滚动截图控制器：隐藏覆盖层后，反复滚动 + 截取选区，最后用 ScrollStitcher 拼成长图。
final class ScrollCaptureController {

    private let config = ScreenshotConfig()
    private let maxFrames = 15
    private let scrollDelay: TimeInterval = 0.25
    private let scrollPixels: Int = 200

    /// 执行滚动截图。
    /// - Parameters:
    ///   - displayID: 目标显示器 ID。
    ///   - rect: 选区（全局屏幕坐标，左上原点）。
    ///   - completion: 完成回调，返回拼接后的长图。
    func capture(displayID: CGDirectDisplayID, rect: CGRect, completion: @escaping (NSImage?) -> Void) {
        let captureRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height)
        var frames: [CGImage] = []

        func captureFrame() -> CGImage? {
            return CGDisplayCreateImage(displayID, rect: captureRect)
        }

        func scrollOnce() {
            // 向下滚动 scrollPixels 像素（负值 = 向下滚）
            for _ in stride(from: 0, to: scrollPixels, by: 40) {
                if let event = CGEvent(scrollWheelEvent2Source: nil,
                                       units: CGScrollEventUnit.pixel,
                                       wheelCount: 1,
                                       wheel1: -40, wheel2: 0, wheel3: 0) {
                    event.post(tap: CGEventTapLocation.cghidEventTap)
                }
            }
        }

        // 采集第 0 帧
        guard let firstFrame = captureFrame() else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        frames.append(firstFrame)

        // 逐帧滚动 + 截取
        let group = DispatchGroup()
        for i in 1..<maxFrames {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                scrollOnce()
                Thread.sleep(forTimeInterval: self.scrollDelay)
                if let frame = captureFrame() {
                    // 判断是否已到底部：与上一帧完全相同则停止
                    if frame !== frames.last, ScrollStitcher.contentChanged(top: frames.last!, bottom: frame) {
                        frames.append(frame)
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            guard frames.count > 1, let stitched = ScrollStitcher.stitch(images: frames) else {
                completion(nil)
                return
            }
            let image = NSImage(cgImage: stitched,
                                size: NSSize(width: stitched.width, height: stitched.height))
            self.saveAndCopy(image: image)
            completion(image)
        }
    }

    /// 判断两帧是否有变化（委托给 ScrollStitcher.contentChanged）。

    private func saveAndCopy(image: NSImage) {
        // 复制到剪贴板
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])

        // 保存到文件
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
