import CoreGraphics
import Foundation

/// 滚动截图拼接器：检测相邻帧之间的垂直重叠区域，将多帧拼接为一张长图。
public enum ScrollStitcher {

    /// 检测 top（上一帧）底部与 bottom（下一帧）顶部的重叠行数。
    /// 允许最多 15% 的行不匹配（光标、滚动条、动画等微小差异）。
    public static func findOverlap(top: CGImage, bottom: CGImage, tolerance: UInt8 = 15) -> Int {
        guard let topBuf = rgbaBuffer(of: top),
              let bottomBuf = rgbaBuffer(of: bottom) else { return 0 }
        let width = min(top.width, bottom.width)
        let maxOverlap = min(top.height, bottom.height)
        guard maxOverlap > 0, width > 0 else { return 0 }

        let columns = sampleColumns(width: width)
        let topBPR = top.width * 4
        let bottomBPR = bottom.width * 4

        // 单次搜索：>=97% 行匹配即认为重叠（允许少量光标/滚动条差异，同时拒绝过渡区误匹配）
        for overlap in stride(from: maxOverlap, through: 1, by: -1) {
            let matchCount = countMatchingRows(
                topBuffer: topBuf.buffer, topBPR: topBPR,
                bottomBuffer: bottomBuf.buffer, bottomBPR: bottomBPR, bottomHeight: bottom.height,
                overlap: overlap, columns: columns, tolerance: tolerance)
            if Double(matchCount) / Double(overlap) >= 0.97 {
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
        var offsets: [Int] = [0]
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
        for i in (0..<images.count).reversed() {
            let yInContext = totalHeight - offsets[i] - images[i].height
            ctx.draw(images[i], in: CGRect(x: 0, y: yInContext, width: width, height: images[i].height))
        }
        return ctx.makeImage()
    }

    // MARK: - 内部

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
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (buffer, bpr)
    }

    private static func sampleColumns(width: Int) -> [Int] {
        if width <= 10 { return Array(0..<width) }
        return [width / 6, width / 4, width / 2, width * 3 / 4, width * 5 / 6]
    }

    /// 比较 top 底部 overlap 行与 bottom 顶部 overlap 行，返回匹配行数。
    private static func countMatchingRows(topBuffer: [UInt8], topBPR: Int,
                                          bottomBuffer: [UInt8], bottomBPR: Int, bottomHeight: Int,
                                          overlap: Int, columns: [Int], tolerance: UInt8) -> Int {
        var matchCount = 0
        for row in 0..<overlap {
            let topRow = row
            let bottomRow = bottomHeight - overlap + row
            var rowMatches = true
            for col in columns {
                let topIdx = topRow * topBPR + col * 4
                let bottomIdx = bottomRow * bottomBPR + col * 4
                guard topIdx + 3 < topBuffer.count, bottomIdx + 3 < bottomBuffer.count else {
                    rowMatches = false; break
                }
                if abs(Int(topBuffer[topIdx]) - Int(bottomBuffer[bottomIdx])) > Int(tolerance) ||
                   abs(Int(topBuffer[topIdx + 1]) - Int(bottomBuffer[bottomIdx + 1])) > Int(tolerance) ||
                   abs(Int(topBuffer[topIdx + 2]) - Int(bottomBuffer[bottomIdx + 2])) > Int(tolerance) {
                    rowMatches = false; break
                }
            }
            if rowMatches { matchCount += 1 }
        }
        return matchCount
    }
}

extension ScrollStitcher {

    /// 判断两张图片是否有明显差异。
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
