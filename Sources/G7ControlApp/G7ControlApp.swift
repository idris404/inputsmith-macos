import AppKit

@main
enum InputSmithApp {
    static func main() {
        if CommandLine.arguments.contains("--self-test") {
            SelfTest.run()
            return
        }

        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.regular)
        application.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let scanner = DeviceScanner()
        let contentViewController = MainViewController(scanner: scanner)
        let window = NSWindow(contentViewController: contentViewController)
        window.title = "InputSmith"
        window.setContentSize(NSSize(width: 900, height: 600))
        window.minSize = NSSize(width: 760, height: 500)
        window.center()

        let controller = NSWindowController(window: window)
        windowController = controller
        controller.showWindow(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
