import SwiftUI

/// Basic settings view
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            Form {
                // Timer Settings
                Section("Timer") {
                    HStack {
                        Text("Work Duration")
                        Spacer()
                        Picker("", selection: $appState.workDuration) {
                            ForEach([15, 20, 25, 30, 45, 50, 60], id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .frame(width: 120)
                    }

                    HStack {
                        Text("Break Duration")
                        Spacer()
                        Picker("", selection: $appState.breakDuration) {
                            ForEach([3, 5, 10, 15], id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .frame(width: 120)
                    }
                }

                // Exercise Settings
                Section("Exercise") {
                    HStack {
                        Text("Exercise Type")
                        Spacer()
                        Picker("", selection: $appState.exerciseType) {
                            Text("Sit-to-Stand").tag("sitToStand")
                            Text("Squats").tag("squats")
                            Text("Jumping Jacks").tag("jumpingJacks")
                            Text("Arm Raises").tag("armRaises")
                        }
                        .frame(width: 150)
                    }

                    HStack {
                        Text("Reps Required")
                        Spacer()
                        Stepper("\(appState.repsRequired)", value: $appState.repsRequired, in: 3...30)
                            .frame(width: 120)
                    }
                }

                // Advanced
                Section {
                    Button(action: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            appState.showAdvancedSettings = true
                        }
                    }) {
                        HStack {
                            Text("Advanced Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Debug
                #if DEBUG
                Section("Debug") {
                    Button("Reset Onboarding") {
                        appState.resetOnboarding()
                        dismiss()
                    }
                    .foregroundColor(.red)

                    HStack {
                        Text("Sessions Completed")
                        Spacer()
                        Text("\(appState.totalSessionsCompleted)")
                            .foregroundColor(.secondary)
                    }
                }
                #endif
            }
            .formStyle(.grouped)
        }
        .frame(width: 450, height: 450)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
