import AppKit
import SwiftUI
import NovaPlayerKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var pendingURL: URL?
    private var isReady: Bool = false
    
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        setupWindow()
        
        isReady = true
        
        // Priority 1: Pending URL opened via Finder / "Open With" during launch
        if let pending = pendingURL {
            openMediaFile(url: pending)
            pendingURL = nil
        }
        // Priority 2: Check if video URL passed as CLI argument
        else if CommandLine.arguments.count > 1 {
            let path = CommandLine.arguments[1]
            let url = URL(fileURLWithPath: path)
            openMediaFile(url: url)
        }
    }
    
    private func setupWindow() {
        let contentRect = NSRect(x: 0, y: 0, width: 960, height: 540)
        
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.collectionBehavior = [.fullScreenPrimary, .participatesInCycle]
        
        // Hide standard window buttons so custom cinema traffic lights are used
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        window.isMovableByWindowBackground = true
        window.backgroundColor = .black
        window.isOpaque = true
        window.hasShadow = true
        window.minSize = NSSize(width: 480, height: 270)
        window.center()
        
        let root = NovaPlayerRootView(engine: PlaybackEngine.shared, state: PlayerState.shared)
        let hostingView = NSHostingView(rootView: root)
        hostingView.autoresizingMask = [.width, .height]
        window.contentView = hostingView
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
    
    // Support opening files via Finder ("Open With" / Double-Click / Drag onto Dock)
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        if let first = filenames.first {
            let url = URL(fileURLWithPath: first)
            if isReady {
                DispatchQueue.main.async { [weak self] in
                    self?.openMediaFile(url: url)
                }
            } else {
                pendingURL = url
            }
        }
        sender.reply(toOpenOrPrint: .success)
    }
    
    private func openMediaFile(url: URL) {
        PlaybackEngine.shared.loadVideo(url: url)
        ThumbnailService().setAsset(url: url)
    }
    
    private func setupMainMenu() {
        let mainMenu = NSMenu()
        
        // App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About NovaPlayer", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide NovaPlayer", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h").keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit NovaPlayer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // File Menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)
        
        // View Menu (Fullscreen shortcut)
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        let fsItem = viewMenu.addItem(withTitle: "Toggle Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        fsItem.keyEquivalentModifierMask = [NSEvent.ModifierFlags.control, NSEvent.ModifierFlags.command]
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)
        
        // Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        
        NSApplication.shared.mainMenu = mainMenu
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
