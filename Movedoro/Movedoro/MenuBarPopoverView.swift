import SwiftUI

/// Compact popover view shown when clicking the menu bar icon
struct MenuBarPopoverView: View {
    @ObservedObject var timer: PomodoroTimer
    @ObservedObject var appState: AppState
    var onShowTimer: () -> Void
    var onQuit: () -> Void
    var onStartWithAnimation: () -> Void

    @State private var isAnimatingOut = false

    var body: some View {
        VStack(spacing: 16) {
            // Timer display
            VStack(spacing: 4) {
                Text(timer.sessionType.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(timer.timeString)
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .monospacedDigit()

                if timer.timerState == .paused {
                    Text("PAUSED")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .fontWeight(.bold)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(timer.sessionType == .work ? Color.workAccent : Color.breakAccent)
                        .frame(width: geometry.size.width * timer.progress, height: 8)
                }
            }
            .frame(height: 8)

            // Control buttons
            HStack(spacing: 12) {
                if timer.timerState == .idle {
                    Button(action: startWithAnimation) {
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: { timer.togglePause() }) {
                        Image(systemName: timer.timerState == .running ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)

                    Button(action: { timer.reset() }) {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Divider()

            // Bottom buttons
            HStack {
                Button(action: onShowTimer) {
                    Label("Show Timer", systemImage: "clock")
                        .font(.caption)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    appState.showSettings = true
                    onShowTimer()
                }) {
                    Image(systemName: "gear")
                        .font(.caption)
                }
                .buttonStyle(.plain)

                Button(action: onQuit) {
                    Image(systemName: "power")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 200)
        .scaleEffect(isAnimatingOut ? 0.3 : 1.0)
        .offset(y: isAnimatingOut ? -100 : 0)
        .opacity(isAnimatingOut ? 0 : 1)
    }

    private func startWithAnimation() {
        // Start the timer
        timer.startWorkSession()

        // Animate out
        withAnimation(.easeIn(duration: 0.25)) {
            isAnimatingOut = true
        }

        // Close popover after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onStartWithAnimation()
        }
    }
}

#Preview {
    MenuBarPopoverView(
        timer: PomodoroTimer(),
        appState: AppState(),
        onShowTimer: {},
        onQuit: {},
        onStartWithAnimation: {}
    )
}
