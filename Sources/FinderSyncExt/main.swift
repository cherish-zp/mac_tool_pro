import Foundation

// App extensions are launched by the system through NSExtensionMain, which reads
// NSExtensionPrincipalClass from Info.plist and instantiates it. The symbol lives
// in Foundation but is not exposed in a public header, so we reference it directly.
@_silgen_name("NSExtensionMain")
private func NSExtensionMain(_ argc: Int32, _ argv: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>) -> Int32

_ = NSExtensionMain(CommandLine.argc, CommandLine.unsafeArgv)
