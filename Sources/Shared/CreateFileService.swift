import Foundation

/// App 侧建文件服务（非沙盒，可写任意目录）：按目录现有文件名去重后创建空文件。
/// 由菜单栏 App 监听扩展发来的请求队列并调用本服务。
public final class CreateFileService {
    public init() {}

    /// 依据请求在指定目录创建文件，返回创建的文件 URL（失败返回 nil）。
    @discardableResult
    public func createFile(request: CreateFileRequest) -> URL? {
        createFile(in: request.directory, baseName: request.baseName)
    }

    /// 在 directory 内按 baseName 创建空文件，文件名与目录现有文件冲突时自动去重。
    @discardableResult
    public func createFile(in directory: URL, baseName: String) -> URL? {
        let existing = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        let name = FileNameResolver.unique(baseName: baseName, existingNames: Set(existing))
        let url = directory.appendingPathComponent(name)
        let created = FileManager.default.createFile(atPath: url.path, contents: nil)
        return created ? url : nil
    }
}
