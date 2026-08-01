import Foundation

/// 在已存在文件名集合中为 baseName 生成不冲突的文件名。
/// 例："新建文件.txt" -> 若存在则 "新建文件 2.txt"、"新建文件 3.txt"...
/// 比较区分大小写（与 POSIX 文件系统默认一致）。
public enum FileNameResolver {
    public static func unique(baseName: String, existingNames: Set<String>) -> String {
        if !existingNames.contains(baseName) { return baseName }
        let stem = (baseName as NSString).deletingPathExtension
        let ext = (baseName as NSString).pathExtension
        var index = 2
        while true {
            let candidate = ext.isEmpty ? "\(stem) \(index)" : "\(stem) \(index).\(ext)"
            if !existingNames.contains(candidate) { return candidate }
            index += 1
        }
    }
}
