import SwiftUI

/// Central app state managing navigation and settings
class AppState: ObservableObject {
    // MARK: - Navigation
    @Published var currentScreen: Screen = .pomodoro
    @Published var showExerciseOverlay: Bool = false
    @Published var showSettings: Bool = false
    @Published var showAdvancedSettings: Bool = false

    enum Screen {
        case onboarding
        case pomodoro
    }

    // MARK: - Onboarding
    @Published var isOnboardingComplete: Bool {
        didSet { UserDefaults.standard.set(isOnboardingComplete, forKey: Keys.isOnboardingComplete) }
    }

    // MARK: - Settings
    @Published var workDuration: Int {
        didSet { UserDefaults.standard.set(workDuration, forKey: Keys.workDuration) }
    }

    @Published var breakDuration: Int {
        didSet { UserDefaults.standard.set(breakDuration, forKey: Keys.breakDuration) }
    }

    @Published var repsRequired: Int {
        didSet { UserDefaults.standard.set(repsRequired, forKey: Keys.repsRequired) }
    }

    @Published var exerciseType: String {
        didSet { UserDefaults.standard.set(exerciseType, forKey: Keys.exerciseType) }
    }

    // MARK: - Stats
    @Published var totalSessionsCompleted: Int {
        didSet { UserDefaults.standard.set(totalSessionsCompleted, forKey: Keys.totalSessionsCompleted) }
    }

    // MARK: - Keys
    private enum Keys {
        static let isOnboardingComplete = "app.isOnboardingComplete"
        static let workDuration = "settings.workDuration"
        static let breakDuration = "settings.breakDuration"
        static let repsRequired = "settings.repsRequired"
        static let exerciseType = "settings.exerciseType"
        static let totalSessionsCompleted = "app.totalSessionsCompleted"
    }

    // MARK: - Init
    init() {
        // Load persisted values or use defaults
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: Keys.isOnboardingComplete)
        self.workDuration = UserDefaults.standard.object(forKey: Keys.workDuration) as? Int ?? 25
        self.breakDuration = UserDefaults.standard.object(forKey: Keys.breakDuration) as? Int ?? 5
        self.repsRequired = UserDefaults.standard.object(forKey: Keys.repsRequired) as? Int ?? 10
        self.exerciseType = UserDefaults.standard.string(forKey: Keys.exerciseType) ?? "sitToStand"
        self.totalSessionsCompleted = UserDefaults.standard.integer(forKey: Keys.totalSessionsCompleted)

        // Set initial screen based on onboarding status
        self.currentScreen = isOnboardingComplete ? .pomodoro : .onboarding
    }

    // MARK: - Actions
    func completeOnboarding() {
        isOnboardingComplete = true
        currentScreen = .pomodoro
    }

    func triggerExerciseBreak() {
        showExerciseOverlay = true
    }

    func completeExercise() {
        showExerciseOverlay = false
        totalSessionsCompleted += 1
    }

    func resetOnboarding() {
        isOnboardingComplete = false
        currentScreen = .onboarding
    }
}
