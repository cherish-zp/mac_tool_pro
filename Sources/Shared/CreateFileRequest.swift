import Foundation

/// 扩展发给 App 的"新建文件"请求：在 directory 内创建名为 baseName 的文件。
/// 文件名去重由 App 侧负责（用 FileNameResolver），请求只携带基础名。
public struct CreateFileRequest: Codable, Equatable {
    public let directory: URL
    public let baseName: String

    public init(directory: URL, baseName: String) {
        self.directory = directory
        self.baseName = baseName
    }
}
