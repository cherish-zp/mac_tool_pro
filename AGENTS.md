# 仓库指南

macOS 菜单栏应用 + Finder Sync 扩展（arm64，macOS 13+）。可扩展的 `Tool` 协议；已实现「复制路径」「新建文件」。

## 项目结构

- `Sources/App/` - 菜单栏容器应用（非沙盒）；运行请求轮询处理器。
- `Sources/FinderSyncExt/` - 沙盒 Finder Sync 扩展；构建右键菜单并分发工具。
- `Sources/Shared/` - `Tool` 协议、注册表、各工具、IPC、配置；同时编入应用、扩展与测试。
- `Tests/mac_tool_proTests/` - XCTest 单元测试（TDD）。
- `Resources/` - Info.plist 与 entitlements。
- `project.yml` - xcodegen 工程定义（事实来源；`*.xcodeproj` 为生成物）。

## 构建、测试、运行

Xcode 工具链需 `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`。

- 增删文件后重新生成工程：`xcodegen generate`
- 构建 + 打包 DMG（自动签名，团队 `77SQ3JU8MG`）：`./package.sh`
- 运行测试：
  ```
  xcodebuild test -scheme mac_tool_proTests -destination 'platform=macOS' \
    -derivedDataPath build/DerivedData CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
  ```
- 本地运行：构建后 `open build/DerivedData/Build/Products/Release/mac_tool_pro.app`。

## 代码风格与规范

- Swift 5，4 空格缩进，不加许可证头。
- 新功能 = 在 `Sources/Shared/` 新增一个 `Tool` 实现并在 `ToolRegistry.init` 注册。
- 逻辑保持纯函数并通过协议注入（`Pasteboard`、`FileCreator`、`FileSystemInspector`），便于单测；副作用（剪贴板、文件系统、IPC）藏在这些抽象之后。
- **Entitlements**：只在 `project.yml` 的 `entitlements.properties` 修改，切勿手改 `.entitlements` 文件（xcodegen 每次 `generate` 会重写）。

## Finder Sync 注意事项

- 扩展必须 `app-sandbox = true`，否则系统不注册。
- 设 `menu.autoenablesItems = false`，否则菜单项被自动禁用、点击不触发。
- 不要用 `NSMenuItem.representedObject` 传数据——它跨进程到 Finder 时不保留。改用 `tag` + `ToolInvocationTable`。
- 诊断：扩展把日志写到容器内 `diag.log`（沙盒下 `os_log` 用 `log show` 抓不到）。

## 测试

- XCTest，TDD（RED -> GREEN）。每个单元一个测试文件；副作用用 spy/stub 注入。
- 提交前运行，保持全绿。

## 提交规范

- 规范化前缀（`fix:`、`feat:`）+ 简洁中文摘要；正文说明根因。
- 不得提交 `build/`、`dist/`、`*.xcodeproj/`（均已 gitignore）。

## Agent 专属要求

- **必须使用中文回复用户。**
- 涉及 entitlements 或 Finder Sync 行为的修改，先阅读本文件「Finder Sync 注意事项」。
