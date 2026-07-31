# mac_tool_pro 设计文档

- 日期: 2026-07-31
- 状态: 已确认,首个工具已实现

## 目标

一个面向 Mac (Apple Silicon) 的、可扩展的小工具集合程序。通过 Finder 右键菜单和菜单栏
提供各类小工具,工具以统一协议接入,便于持续新增。

## 关键决策

1. **技术栈**: 原生 Swift macOS App(菜单栏常驻)+ Finder Sync Extension。Finder Sync
   是 macOS 上给 Finder 右键菜单添加条目的官方标准方式。
2. **可扩展性**: 定义 `Tool` 协议,工具实现协议并注册到 `ToolRegistry`;复制路径为首个实现。
   现阶段为内建模块,协议设计保持简洁,未来可演进为运行时插件加载。
3. **分发**: 直接分发(签名 + 公证),非沙盒。主程序与扩展通过共享配置文件通信,文件操作不受
   沙盒限制。
4. **首个工具**: 复制 POSIX 绝对路径到剪贴板,多选时换行分隔。

## 架构

```
mac_tool_pro.app
├── Contents/MacOS/mac_tool_pro          主程序(菜单栏 App,LSUIElement)
└── Contents/PlugIns/FinderSyncExt.appex Finder Sync 扩展(右键菜单)
```

共享层 `Sources/Shared` 编译进两个 target:

- `Tool.swift` - 工具协议(id / title / image / canPerform / perform)
- `ToolRegistry.swift` - 所有工具的注册中心
- `CopyPathTool.swift` - 复制路径工具
- `ToolConfig.swift` - 工具启用状态持久化(共享 JSON 配置)
- `Clipboard.swift` - 剪贴板写入

主程序 `Sources/App`:菜单栏状态项,列出所有工具并以勾选项开关;切换时写入共享配置。
扩展 `Sources/FinderSyncExt`:`FIFinderSync` 子类,观察 `/` 全盘,右键时读取共享配置,按
启用且适用的工具构建菜单并执行。

### 配置共享

非沙盒,主程序与扩展同账号,共同读写
`~/Library/Application Support/mac_tool_pro/config.json`。扩展每次构建菜单时读取最新状态。

## 构建

`./build.sh` 使用 `swiftc` 直接构建,不依赖完整 Xcode。产物为 `build/mac_tool_pro.app`。
详见 README 的「构建」一节。

## 分发

后续用 Developer ID 签名 + notarization 公证,配合 Sparkle 等做自动更新。当前为本地 ad-hoc
签名。

## 可扩展性路线

1. 新增工具:实现 `Tool` 协议,在 `ToolRegistry.init` 注册。
2. 菜单结构:单工具直接显示,多工具自动收纳到「mac_tool_pro」子菜单。
3. 未来插件化:将 `Tool` 协议固化,扩展支持加载外部 `.bundle`,按 `id` 路由。
