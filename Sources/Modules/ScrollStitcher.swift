import CoreGraphics
import Foundation

/// 滚动截图拼接器：检测相邻帧之间的垂直重叠区域，将多帧拼接为一张长图。
/// 纯函数 + CGImage 操作，便于单测。
public enum ScrollStitcher {

    /// 检测 top（上一帧）底部与 bottom（下一帧）顶部的重叠行数。
    /// 从最大可能重叠开始向下搜索，首个匹配即为结果。
    public static func findOverlap(top: CGImage, bottom: CGImage, tolerance: UInt8 = 8) -> Int {
        guard let topBuf = rgbaBuffer(of: top),
              let bottomBuf = rgbaBuffer(of: bottom) else { return 0 }
        let width = min(top.width, bottom.width)
        let maxOverlap = min(top.height, bottom.height)
        guard maxOverlap > 0, width > 0 else { return 0 }

        let columns = sampleColumns(width: width)
        let topBPR = top.width * 4
        let bottomBPR = bottom.width * 4

        for overlap in stride(from: maxOverlap, through: 1, by: -1) {
            if rowsMatch(topBuffer: topBuf.buffer, topBPR: topBPR, topHeight: top.height,
                         bottomBuffer: bottomBuf.buffer, bottomBPR: bottomBPR,
                         overlap: overlap, columns: columns, tolerance: tolerance) {
                return overlap
            }
        }
        return 0
    }

    /// 将多帧图片垂直拼接，自动去除相邻帧的重叠部分，返回拼接后的长图。
    public static func stitch(images: [CGImage]) -> CGImage? {
        guard let first = images.first else { return nil }
        if images.count == 1 { return first }

        let width = first.width
        var offsets: [Int] = [0]  // 每帧在结果中的顶部 Y 偏移（左上原点）
        var totalHeight = first.height

        for i in 1..<images.count {
            let overlap = findOverlap(top: images[i - 1], bottom: images[i])
            let offset = offsets[i - 1] + images[i - 1].height - overlap
            offsets.append(offset)
            totalHeight = offset + images[i].height
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: width, height: totalHeight,
                                  bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        // CGContext 原点在左下，从最后一帧往前画（后面的帧在上，先画）
        for i in (0..<images.count).reversed() {
            let yInContext = totalHeight - offsets[i] - images[i].height
            ctx.draw(images[i], in: CGRect(x: 0, y: yInContext, width: width, height: images[i].height))
        }
        return ctx.makeImage()
    }

    // MARK: - 内部

    /// 将 CGImage 转为 RGBA 缓冲区（翻转后 buffer 行 0 = 图片顶部）。
    private static func rgbaBuffer(of image: CGImage) -> (buffer: [UInt8], bytesPerRow: Int)? {
        let width = image.width
        let height = image.height
        let bpr = width * 4
        var buffer = [UInt8](repeating: 0, count: bpr * height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: &buffer, width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: bpr, space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        // 翻转：让 buffer 行 0 对应图片顶部
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (buffer, bpr)
    }

    private static func sampleColumns(width: Int) -> [Int] {
        if width <= 5 { return Array(0..<width) }
        return [0, width / 4, width / 2, width * 3 / 4, width - 1]
    }

    /// 比较 top 底部 overlap 行与 bottom 顶部 overlap 行是否匹配。
    private static func rowsMatch(topBuffer: [UInt8], topBPR: Int, topHeight: Int,
                                  bottomBuffer: [UInt8], bottomBPR: Int,
                                  overlap: Int, columns: [Int], tolerance: UInt8) -> Bool {
        for row in 0..<overlap {
            let topRow = topHeight - overlap + row  // top 图片中的行号（顶部=0）
            let bottomRow = row                      // bottom 图片中的行号（顶部=0）
            for col in columns {
                let topIdx = topRow * topBPR + col * 4
                let bottomIdx = bottomRow * bottomBPR + col * 4
                guard topIdx + 3 < topBuffer.count, bottomIdx + 3 < bottomBuffer.count else { return false }
                if abs(Int(topBuffer[topIdx]) - Int(bottomBuffer[bottomIdx])) > Int(tolerance) ||
                   abs(Int(topBuffer[topIdx + 1]) - Int(bottomBuffer[bottomIdx + 1])) > Int(tolerance) ||
                   abs(Int(topBuffer[topIdx + 2]) - Int(bottomBuffer[bottomIdx + 2])) > Int(tolerance) {
                    return false
                }
            }
        }
        return true
    }
}

// MARK: - 内容变化检测

extension ScrollStitcher {

    /// 判断两张图片是否有明显差异（用于滚动截图判断是否已到底部）。
    /// 采样比较部分像素，任一差异超过 tolerance 即返回 true。
    public static func contentChanged(top: CGImage, bottom: CGImage, tolerance: UInt8 = 5) -> Bool {
        guard let topBuf = rgbaBuffer(of: top),
              let bottomBuf = rgbaBuffer(of: bottom) else { return true }
        let minLen = min(topBuf.buffer.count, bottomBuf.buffer.count)
        guard minLen > 0 else { return true }
        let stride = max(1, minLen / 400)
        var i = 0
        while i < minLen {
            if abs(Int(topBuf.buffer[i]) - Int(bottomBuf.buffer[i])) > Int(tolerance) { return true }
            i += stride
        }
        return false
    }
}
