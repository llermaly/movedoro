import AppKit
import SwiftUI
import Combine

/// Manages the menu bar status item for the pomodoro timer
class MenuBarController: NSObject, ObservableObject, NSWindowDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()
    private weak var pomodoroTimer: PomodoroTimer?
    private weak var appState: AppState?
    private weak var mainWindow: NSWindow?
    private var eventMonitor: Any?

    static let shared = MenuBarController()

    private override init() {
        super.init()
    }

    /// Setup the menu bar item with timer subscription
    func setup(timer: PomodoroTimer, appState: AppState) {
        self.pomodoroTimer = timer
        self.appState = appState

        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Configure button with click action
        if let button = statusItem?.button {
            updateButton(timeRemaining: timer.timeRemaining, state: timer.timerState, sessionType: timer.sessionType)
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp])
        }

        // Create the popover
        setupPopover()

        // Set up window delegate to intercept close/minimize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupWindowDelegate()
        }

        // Subscribe to timer updates
        timer.$timeRemaining
            .combineLatest(timer.$timerState, timer.$sessionType)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timeRemaining, state, sessionType in
                self?.updateButton(timeRemaining: timeRemaining, state: state, sessionType: sessionType)
            }
            .store(in: &cancellables)
    }

    /// Update the status bar button display
    private func updateButton(timeRemaining: Int, state: PomodoroTimer.TimerState, sessionType: PomodoroTimer.SessionType) {
        guard let button = statusItem?.button else { return }

        switch state {
        case .idle:
            // Show tomato icon when idle
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Pomodoro Timer")
            button.title = ""

        case .running, .paused:
            // Show time remaining
            let minutes = timeRemaining / 60
            let seconds = timeRemaining % 60
            let timeString = String(format: "%02d:%02d", minutes, seconds)

            // Set icon based on session type
            let iconName = sessionType == .work ? "circle.fill" : "leaf.fill"
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: sessionType.label)
            button.title = " \(timeString)"

            // Dim if paused
            button.alphaValue = state == .paused ? 0.6 : 1.0
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        guard let timer = pomodoroTimer, let appState = appState else { return }

        let popoverView = MenuBarPopoverView(
            timer: timer,
            appState: appState,
            onShowTimer: { [weak self] in
                self?.closePopover()
                self?.showTimerWindow()
            },
            onQuit: { [weak self] in
                self?.closePopover()
                self?.quitApp()
            },
            onStartWithAnimation: { [weak self] in
                // Just close the popover - the animation already happened in the view
                self?.closePopover()
            }
        )

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 220, height: 240)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: popoverView)
        popover.delegate = self

        self.popover = popover
    }

    @objc private func statusItemClicked() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            closePopover()
        } else {
            // Refresh the popover content
            setupPopover()
            self.popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            startEventMonitor()
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
        stopEventMonitor()
    }

    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - NSPopoverDelegate

    func popoverDidClose(_ notification: Notification) {
        stopEventMonitor()
    }

    /// Hide all windows and remove from Dock - only menu bar visible
    func hideToMenuBarOnly() {
        // Hide all app windows
        for window in NSApp.windows {
            if window.canBecomeKey && !(window is NSPanel) {
                window.orderOut(nil)
            }
        }

        // Remove from Dock
        NSApp.setActivationPolicy(.accessory)
    }

    /// Find and set up delegate for the main window
    private func setupWindowDelegate() {
        for window in NSApp.windows {
            if window.canBecomeKey && !(window is NSPanel) {
                mainWindow = window
                window.delegate = self
                break
            }
        }
    }

    // MARK: - NSWindowDelegate

    /// Intercept close button - hide to menu bar instead of closing
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hideToMenuBarOnly()
        return false // Prevent actual close
    }

    /// Intercept minimize - hide to menu bar instead
    func windowWillMiniaturize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        // Cancel the miniaturization and hide instead
        DispatchQueue.main.async {
            window.deminiaturize(nil)
            self.hideToMenuBarOnly()
        }
    }

    @objc private func showTimerWindow() {
        // Restore to regular app (shows in Dock)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Use stored main window reference if available
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }

        // Fallback: find the main app window
        for window in NSApp.windows {
            guard window.canBecomeKey else { continue }
            guard !(window is NSPanel) else { continue }

            mainWindow = window
            window.delegate = self
            window.makeKeyAndOrderFront(nil)
            return
        }
    }

    @objc private func toggleTimer() {
        guard let timer = pomodoroTimer else { return }

        if timer.timerState == .idle {
            timer.startWorkSession()
        } else {
            timer.togglePause()
        }
    }

    @objc private func resetTimer() {
        pomodoroTimer?.reset()
    }

    @objc private func showHistory() {
        NSApp.activate(ignoringOtherApps: true)
        appState?.showScheduleView()
        showTimerWindow()
    }

    @objc private func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        appState?.showSettings = true
        showTimerWindow()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    /// Remove the status item
    func teardown() {
        NotificationCenter.default.removeObserver(self)
        stopEventMonitor()
        closePopover()
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
        popover = nil
        cancellables.removeAll()
    }
}
