import XCTest
import CoreGraphics

/// TDD: 画笔路径构建器 - 自由绘制时管理点序列，最小距离过滤避免点过密。
final class PenPathBuilderTests: XCTestCase {

    func test_firstPointAlwaysAdded() {
        var points: [CGPoint] = []
        XCTAssertTrue(PenPathBuilder.append(CGPoint(x: 10, y: 20), to: &points))
        XCTAssertEqual(points.count, 1)
        XCTAssertEqual(points[0], CGPoint(x: 10, y: 20))
    }

    func test_pointTooCloseIsIgnored() {
        var points: [CGPoint] = [CGPoint(x: 100, y: 100)]
        // 距离 1pt < 最小距离 2pt -> 忽略
        XCTAssertFalse(PenPathBuilder.append(CGPoint(x: 101, y: 100), to: &points))
        XCTAssertEqual(points.count, 1)
    }

    func test_pointFarEnoughIsAdded() {
        var points: [CGPoint] = [CGPoint(x: 100, y: 100)]
        // 距离 5pt > 最小距离 2pt -> 添加
        XCTAssertTrue(PenPathBuilder.append(CGPoint(x: 105, y: 100), to: &points))
        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points[1], CGPoint(x: 105, y: 100))
    }

    func test_multiplePointsAccumulate() {
        var points: [CGPoint] = []
        PenPathBuilder.append(CGPoint(x: 0, y: 0), to: &points)
        PenPathBuilder.append(CGPoint(x: 10, y: 0), to: &points)
        PenPathBuilder.append(CGPoint(x: 11, y: 0), to: &points) // 太近，忽略
        PenPathBuilder.append(CGPoint(x: 20, y: 5), to: &points)
        XCTAssertEqual(points.count, 3)
        XCTAssertEqual(points.last, CGPoint(x: 20, y: 5))
    }

    func test_annotationTypeIncludesPen() {
        XCTAssertTrue(AnnotationType.allCases.contains(.pen))
    }
}
