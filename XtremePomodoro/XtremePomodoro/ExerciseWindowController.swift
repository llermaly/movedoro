import SwiftUI
import AppKit

/// Manages a fullscreen blocking window for exercise breaks
class ExerciseWindowController: NSObject, ObservableObject {
    private var window: NSPanel?
    private var appState: AppState?
    private var cameraManager: OBSBOTManager?

    static let shared = ExerciseWindowController()

    private override init() {
        super.init()
    }

    /// Show the fullscreen exercise overlay
    func showExerciseWindow(appState: AppState, cameraManager: OBSBOTManager) {
        self.appState = appState
        self.cameraManager = cameraManager

        // Create the SwiftUI view
        let exerciseView = ExerciseOverlayView()
            .environmentObject(appState)
            .environmentObject(cameraManager)

        // Create hosting view
        let hostingView = NSHostingView(rootView: exerciseView)

        // Get the main screen size
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame

        // Create NSPanel with specific style
        let panel = NSPanel(
            contentRect: screenFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Configure panel for fullscreen blocking
        panel.contentView = hostingView
        panel.backgroundColor = .black
        panel.isOpaque = true
        panel.hasShadow = false

        // Set to highest window level (above everything including dock and menu bar)
        panel.level = .screenSaver

        // Make it cover the entire screen including menu bar
        panel.setFrame(screenFrame, display: true)

        // Prevent it from being hidden or moved
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovable = false
        panel.isMovableByWindowBackground = false

        // Make it key and front
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()

        // Hide the cursor (optional - can be commented out if annoying)
        // NSCursor.hide()

        // Store reference
        self.window = panel

        // Set up keyboard monitoring for Cmd+Q escape
        setupKeyboardMonitor()

        // Hide dock and menu bar
        NSApp.presentationOptions = [.hideDock, .hideMenuBar, .disableProcessSwitching]
    }

    /// Dismiss the exercise window
    func dismissExerciseWindow() {
        // Restore normal presentation
        NSApp.presentationOptions = []

        // Show cursor
        NSCursor.unhide()

        // Remove keyboard monitor
        removeKeyboardMonitor()

        // Close and release window
        window?.close()
        window = nil

        // Clear references
        appState = nil
        cameraManager = nil
    }

    // MARK: - Keyboard Monitoring

    private var keyMonitor: Any?

    private func setupKeyboardMonitor() {
        // Monitor for Cmd+Q to allow emergency exit
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Check for Cmd+Q
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "q" {
                // Show confirmation alert
                self?.showQuitConfirmation()
                return nil // Consume the event
            }
            return event
        }
    }

    private func removeKeyboardMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func showQuitConfirmation() {
        // Temporarily lower window level to show alert
        let previousLevel = window?.level ?? .screenSaver
        window?.level = .normal

        let alert = NSAlert()
        alert.messageText = "Quit XtremePomodoro?"
        alert.informativeText = "Are you sure you want to quit? You haven't finished your exercise yet!\n\nPress Cmd+Q again to confirm quit."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Keep Exercising")
        alert.addButton(withTitle: "Quit Anyway")

        let response = alert.runModal()

        if response == .alertSecondButtonReturn {
            // User chose to quit
            dismissExerciseWindow()
            NSApp.terminate(nil)
        } else {
            // Restore window level
            window?.level = previousLevel
            window?.makeKeyAndOrderFront(nil)
            window?.orderFrontRegardless()
        }
    }
}

/// Coordinator to bridge between SwiftUI and the window controller
class ExerciseWindowCoordinator: ObservableObject {
    @Published var isShowingExercise: Bool = false {
        didSet {
            if isShowingExercise {
                // Window will be shown by the App
            } else {
                ExerciseWindowController.shared.dismissExerciseWindow()
            }
        }
    }
}
