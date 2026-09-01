import XCTest
import CoreGraphics

/// TDD: 截图渲染管线颜色均匀性回归。
/// 用户报告"截图下半部分比上半部分颜色深"：渲染管线各环节（圆角/描边）
/// 必须保持逐像素均匀，均匀输入不得产生纵向亮度渐变。
/// 用 CGDataProvider 原始字节读写（零色彩管理），字节级断言；
/// 上下文一律 data: nil（CG 自管内存），不做裸指针缓冲。
final class ScreenshotImagePipelineTests: XCTestCase {

    private let colorSpace = CGColorSpaceCreateDeviceRGB()

    /// 直接写字节生成 width×height 纯色不透明测试图（deviceRGB 同色空间填充，字节保真）。
    private func uniformImage(width: Int, height: Int, red: UInt8, green: UInt8, blue: UInt8) -> CGImage? {
        guard let ctx = CGContext(data: nil, width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let color = CGColor(colorSpace: colorSpace,
                            components: [CGFloat(red) / 255, CGFloat(green) / 255, CGFloat(blue) / 255, 1])!
        ctx.setFillColor(color)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage()
    }

    /// 从 CGDataProvider 读取原始字节（row 0 = 图片顶部）。
    /// 注意 CG 会按 32 字节对齐填充行（bytesPerRow ≠ width×4 必然存在于部分宽度），
    /// 必须用 实际长度/行数 推导步长。
    private func rawBytes(_ image: CGImage) -> (bytes: [UInt8], stride: Int)? {
        guard let data = image.dataProvider?.data as Data?,
              image.height > 0 else { return nil }
        let bytes = [UInt8](data)
        let rowStride = data.count / image.height
        guard rowStride >= image.width * 4 else { return nil }
        return (bytes, rowStride)
    }

    private struct Sample {
        var r: Double, g: Double, b: Double, a: Double
    }

    /// 指定行范围（顶部原点）中心列的平均分量，字节级精确。
    private func bandMean(_ image: CGImage, rows: Range<Int>) -> Sample? {
        guard let (bytes, rowStride) = rawBytes(image) else { return nil }
        let w = image.width
        var r = 0.0, g = 0.0, b = 0.0, a = 0.0
        var count = 0
        for y in rows {
            for x in stride(from: w / 4, to: w * 3 / 4, by: 2) {
                let off = y * rowStride + x * 4
                guard off + 3 < bytes.count else { continue }
                r += Double(bytes[off]); g += Double(bytes[off + 1])
                b += Double(bytes[off + 2]); a += Double(bytes[off + 3])
                count += 1
            }
        }
        guard count > 0 else { return nil }
        return Sample(r: r / Double(count), g: g / Double(count), b: b / Double(count), a: a / Double(count))
    }

    /// 读取单像素（顶部原点坐标）。
    private func pixel(_ image: CGImage, x: Int, y: Int) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8)? {
        guard let (bytes, rowStride) = rawBytes(image) else { return nil }
        let off = y * rowStride + x * 4
        guard off + 3 < bytes.count else { return nil }
        return (bytes[off], bytes[off + 1], bytes[off + 2], bytes[off + 3])
    }

    func test_roundedCorners_uniformStaysUniformAcrossRows() throws {
        let input = try XCTUnwrap(uniformImage(width: 200, height: 100, red: 128, green: 128, blue: 128))
        let output = try XCTUnwrap(ScreenshotImagePipeline.applyRoundedCorners(to: input, radius: 16))
        let top = try XCTUnwrap(bandMean(output, rows: 30..<40))
        let bottom = try XCTUnwrap(bandMean(output, rows: 60..<70))
        XCTAssertEqual(top.r, bottom.r, accuracy: 0.002, "圆角环节不得产生纵向颜色渐变")
        XCTAssertEqual(top.g, bottom.g, accuracy: 0.002)
        XCTAssertEqual(top.b, bottom.b, accuracy: 0.002)
        XCTAssertEqual(top.a, 255.0, accuracy: 0.5, "非角落区域应保持不透明")
        XCTAssertEqual(bottom.b, 128.0, accuracy: 0.5, "输出应与输入颜色字节一致")
    }

    func test_roundedCorners_cornersBecomeTransparent() throws {
        let input = try XCTUnwrap(uniformImage(width: 200, height: 100, red: 128, green: 128, blue: 128))
        let output = try XCTUnwrap(ScreenshotImagePipeline.applyRoundedCorners(to: input, radius: 16))
        let corner = try XCTUnwrap(pixel(output, x: 2, y: 2))
        XCTAssertLessThan(Double(corner.a), 128, "圆角处应透明")
    }

    func test_shadowBorder_centerUntouchedAndRowsUniform() throws {
        let input = try XCTUnwrap(uniformImage(width: 200, height: 100, red: 200, green: 100, blue: 50))
        let output = try XCTUnwrap(ScreenshotImagePipeline.applyShadowBorder(to: input, cornerRadius: 16, opacity: 0.16))
        let top = try XCTUnwrap(bandMean(output, rows: 20..<35))
        let bottom = try XCTUnwrap(bandMean(output, rows: 65..<80))
        XCTAssertEqual(top.r, bottom.r, accuracy: 0.002, "描边环节不得产生纵向颜色渐变")
        XCTAssertEqual(top.g, bottom.g, accuracy: 0.002)
        XCTAssertEqual(top.b, bottom.b, accuracy: 0.002)
        // 中心区域不受 1px 描边影响（字节级一致）
        let center = try XCTUnwrap(pixel(output, x: 100, y: 50))
        XCTAssertEqual(center.r, 200)
        XCTAssertEqual(center.g, 100)
        XCTAssertEqual(center.b, 50)
    }

    func test_fullPipeline_uniformInputProducesNoVerticalGradient() throws {
        let input = try XCTUnwrap(uniformImage(width: 300, height: 160, red: 240, green: 240, blue: 240))
        var image = try XCTUnwrap(ScreenshotImagePipeline.applyRoundedCorners(to: input, radius: 16))
        image = try XCTUnwrap(ScreenshotImagePipeline.applyShadowBorder(to: image, cornerRadius: 16, opacity: 0.16))
        let top = try XCTUnwrap(bandMean(image, rows: 40..<60))
        let bottom = try XCTUnwrap(bandMean(image, rows: 100..<120))
        XCTAssertEqual(top.r, bottom.r, accuracy: 0.002)
        XCTAssertEqual(top.g, bottom.g, accuracy: 0.002)
        XCTAssertEqual(top.b, bottom.b, accuracy: 0.002)
        XCTAssertEqual(bottom.b, 240.0, accuracy: 0.5, "输出应与输入颜色字节一致")
    }
}
