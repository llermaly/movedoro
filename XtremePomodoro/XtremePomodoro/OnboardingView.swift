import SwiftUI
import AVFoundation

/// First-time setup wizard
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cameraManager: OBSBOTManager

    @State private var currentStep: Int = 0
    @StateObject private var cameraCapture = CameraCapture()
    @StateObject private var poseDetector = PoseDetector()
    @State private var showPoseOverlay = true

    private let totalSteps = 5

    var body: some View {
        ZStack {
            // Dark background for fullscreen feel
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with progress
                VStack(spacing: 12) {
                    Text("Setup XtremePomodoro")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    // Progress bar
                    HStack(spacing: 6) {
                        ForEach(0..<totalSteps, id: \.self) { step in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(height: 6)
                        }
                    }
                    .padding(.horizontal, 60)

                    // Step indicator
                    Text("Step \(currentStep + 1) of \(totalSteps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 30)
                .padding(.bottom, 20)

                Divider()
                    .padding(.horizontal, 40)

                // Step content
                Group {
                    switch currentStep {
                    case 0: welcomeStep
                    case 1: cameraStep
                    case 2: exerciseStep
                    case 3: calibrationStep
                    case 4: completeStep
                    default: welcomeStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()
                    .padding(.horizontal, 40)

                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }

                    Spacer()

                    if currentStep == totalSteps - 1 {
                        Button("Get Started") {
                            cameraCapture.stopCapture()
                            appState.completeOnboarding()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    } else if currentStep == 3 && appState.exerciseType == "sitToStand" {
                        // Calibration step - show Next if calibrated, Skip otherwise
                        if poseDetector.isCalibrated {
                            Button("Next") {
                                nextStep()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        } else {
                            HStack(spacing: 12) {
                                Button("Skip for now") {
                                    nextStep()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)

                                if poseDetector.calibrationState == .calibrated || poseDetector.calibrationState == .notCalibrated {
                                    Button("Next") {
                                        nextStep()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.large)
                                    .disabled(!poseDetector.isCalibrated)
                                }
                            }
                        }
                    } else {
                        Button("Next") {
                            nextStep()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .padding(30)
            }
        }
        .frame(minWidth: 800, minHeight: 850)
        .onDisappear {
            cameraCapture.stopCapture()
        }
    }

    private func nextStep() {
        // Stop camera when leaving camera/calibration steps
        if currentStep == 1 || currentStep == 3 {
            // Keep camera running if going to calibration from camera
            if !(currentStep == 1 && appState.exerciseType == "sitToStand") {
                // cameraCapture.stopCapture()
            }
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            currentStep += 1
        }
    }

    // MARK: - Step Views

    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "figure.run")
                .font(.system(size: 100))
                .foregroundColor(.blue)

            Text("Welcome to XtremePomodoro")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Stay productive and healthy with enforced exercise breaks")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "clock.fill", title: "Pomodoro Timer", description: "Focus for 25 minutes, then take a break")
                FeatureRow(icon: "figure.stand", title: "Exercise Tracking", description: "Camera tracks your movements in real-time")
                FeatureRow(icon: "lock.fill", title: "Enforced Breaks", description: "Screen locks until you complete your exercise")
            }
            .padding(.top, 30)

            Spacer()
        }
        .padding(50)
    }

    private var cameraStep: some View {
        VStack(spacing: 25) {
            Text("Camera Setup")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Select and test the camera you'll use for exercise tracking")
                .foregroundColor(.secondary)

            // Camera preview - large
            ZStack {
                if cameraCapture.isCapturing {
                    ZStack {
                        CameraPreviewView(cameraCapture: cameraCapture)

                        if showPoseOverlay {
                            PoseOverlayView(pose: poseDetector.currentPose, imageSize: CGSize(width: 640, height: 480))
                        }
                    }
                    .frame(width: 640, height: 480)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(poseDetector.isPersonDetected ? Color.green : Color.gray, lineWidth: 3)
                    )
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 640, height: 480)
                        .overlay(
                            VStack(spacing: 15) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("Click 'Start Camera' to preview")
                                    .foregroundColor(.gray)
                            }
                        )
                }
            }

            // Status
            if cameraCapture.isCapturing {
                HStack {
                    Circle()
                        .fill(poseDetector.isPersonDetected ? Color.green : Color.orange)
                        .frame(width: 12, height: 12)
                    Text(poseDetector.isPersonDetected ? "Person detected" : "No person detected - stand in front of camera")
                        .foregroundColor(poseDetector.isPersonDetected ? .green : .orange)
                }
            }

            // Controls
            HStack(spacing: 20) {
                // Camera selection
                if !cameraCapture.availableCameras.isEmpty {
                    Picker("Camera", selection: Binding(
                        get: { cameraCapture.selectedCamera },
                        set: { if let cam = $0 { cameraCapture.selectCamera(cam) } }
                    )) {
                        ForEach(cameraCapture.availableCameras, id: \.uniqueID) { camera in
                            Text(camera.localizedName).tag(camera as AVCaptureDevice?)
                        }
                    }
                    .frame(width: 250)
                }

                Button(cameraCapture.isCapturing ? "Stop Camera" : "Start Camera") {
                    if cameraCapture.isCapturing {
                        cameraCapture.stopCapture()
                    } else {
                        cameraCapture.poseDetector = poseDetector
                        cameraCapture.startCapture()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(cameraCapture.isCapturing ? .red : .green)

                if cameraCapture.isCapturing {
                    Toggle("Show Skeleton", isOn: $showPoseOverlay)
                        .toggleStyle(.button)
                }
            }

            Spacer()
        }
        .padding(40)
        .onAppear {
            cameraCapture.loadAvailableCameras()
            // Auto-start camera
            if !cameraCapture.isCapturing {
                cameraCapture.poseDetector = poseDetector
                cameraCapture.startCapture()
            }
        }
    }

    private var exerciseStep: some View {
        VStack(spacing: 30) {
            Text("Choose Your Exercise")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Select the exercise you want to do during breaks")
                .foregroundColor(.secondary)

            VStack(spacing: 15) {
                ExerciseOption(
                    title: "Sit-to-Stand",
                    description: "Stand up from sitting position. Great for desk workers. Requires calibration.",
                    icon: "figure.stand",
                    isSelected: appState.exerciseType == "sitToStand"
                ) {
                    appState.exerciseType = "sitToStand"
                }

                ExerciseOption(
                    title: "Squats",
                    description: "Full squat movements. More intense workout.",
                    icon: "figure.strengthtraining.traditional",
                    isSelected: appState.exerciseType == "squats"
                ) {
                    appState.exerciseType = "squats"
                }

                ExerciseOption(
                    title: "Jumping Jacks",
                    description: "Cardio exercise with arm movements.",
                    icon: "figure.jumprope",
                    isSelected: appState.exerciseType == "jumpingJacks"
                ) {
                    appState.exerciseType = "jumpingJacks"
                }

                ExerciseOption(
                    title: "Arm Raises",
                    description: "Simple arm raises. Low impact option.",
                    icon: "figure.arms.open",
                    isSelected: appState.exerciseType == "armRaises"
                ) {
                    appState.exerciseType = "armRaises"
                }
            }
            .frame(maxWidth: 500)

            Spacer()
        }
        .padding(40)
    }

    private var calibrationStep: some View {
        VStack(spacing: 20) {
            Text("Calibrate Your Position")
                .font(.largeTitle)
                .fontWeight(.bold)

            if appState.exerciseType == "sitToStand" {
                Text("Calibration teaches the app your sitting and standing positions")
                    .foregroundColor(.secondary)

                // Large camera preview with pose
                ZStack {
                    CameraPreviewView(cameraCapture: cameraCapture)

                    if showPoseOverlay {
                        PoseOverlayView(pose: poseDetector.currentPose, imageSize: CGSize(width: 640, height: 480))
                    }
                }
                .frame(width: 640, height: 480)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(poseDetector.isCalibrated ? Color.green : Color.blue, lineWidth: 3)
                )

                // Calibration status and controls
                HStack(spacing: 30) {
                    // Status
                    HStack {
                        Circle()
                            .fill(poseDetector.isCalibrated ? Color.green : Color.orange)
                            .frame(width: 14, height: 14)
                        Text(poseDetector.isCalibrated ? "Calibrated" : "Not Calibrated")
                            .font(.headline)
                            .foregroundColor(poseDetector.isCalibrated ? .green : .orange)
                    }

                    // Pose status
                    HStack {
                        Circle()
                            .fill(poseDetector.isPersonDetected ? Color.green : Color.red)
                            .frame(width: 14, height: 14)
                        Text(poseDetector.poseDescription)
                            .foregroundColor(.secondary)
                    }

                    Toggle("Skeleton", isOn: $showPoseOverlay)
                        .toggleStyle(.button)
                }

                // Calibration message / button
                if poseDetector.calibrationState != .notCalibrated &&
                   poseDetector.calibrationState != .calibrated {
                    // Active calibration in progress
                    VStack(spacing: 12) {
                        Text(poseDetector.calibrationMessage)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)

                        Button("Cancel Calibration") {
                            poseDetector.cancelCalibration()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                } else if poseDetector.isCalibrated {
                    // Calibration complete - show success message and options
                    VStack(spacing: 16) {
                        Text("Calibration Complete!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)

                        HStack(spacing: 20) {
                            Button("Re-Calibrate") {
                                poseDetector.startCalibration()
                            }
                            .buttonStyle(.bordered)
                            .tint(.purple)
                            .controlSize(.large)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                } else {
                    // Not calibrated - show start button
                    Button("Start Calibration") {
                        poseDetector.startCalibration()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .controlSize(.large)
                }

                if poseDetector.isCalibrated {
                    HStack {
                        Text("Sit Y: \(String(format: "%.3f", poseDetector.sittingHipY))")
                        Text("|")
                        Text("Stand Y: \(String(format: "%.3f", poseDetector.standingHipY))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

            } else {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("No calibration needed")
                    .font(.title2)
                    .fontWeight(.medium)

                Text("Your selected exercise (\(exerciseDisplayName)) doesn't require calibration")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }

            Spacer()
        }
        .padding(40)
        .onAppear {
            // Ensure camera is running with pose detector
            if !cameraCapture.isCapturing {
                cameraCapture.poseDetector = poseDetector
                cameraCapture.startCapture()
            } else if cameraCapture.poseDetector == nil {
                cameraCapture.poseDetector = poseDetector
            }
        }
    }

    private var completeStep: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)

            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Here's a summary of your settings:")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "clock")
                        .frame(width: 30)
                    Text("Work: \(appState.workDuration) min / Break: \(appState.breakDuration) min")
                }
                HStack {
                    Image(systemName: "figure.stand")
                        .frame(width: 30)
                    Text("Exercise: \(exerciseDisplayName)")
                }
                HStack {
                    Image(systemName: "number")
                        .frame(width: 30)
                    Text("Reps: \(appState.repsRequired) per break")
                }
                HStack {
                    Image(systemName: poseDetector.isCalibrated ? "checkmark.circle.fill" : "exclamationmark.circle")
                        .foregroundColor(poseDetector.isCalibrated ? .green : .orange)
                        .frame(width: 30)
                    Text(poseDetector.isCalibrated ? "Calibration: Complete" : "Calibration: Skipped (can do in settings)")
                        .foregroundColor(poseDetector.isCalibrated ? .primary : .orange)
                }
            }
            .font(.title3)
            .padding(30)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)

            Spacer()
        }
        .padding(50)
        .onAppear {
            // Stop camera on final step
            cameraCapture.stopCapture()
        }
    }

    private var exerciseDisplayName: String {
        switch appState.exerciseType {
        case "sitToStand": return "Sit-to-Stand"
        case "squats": return "Squats"
        case "jumpingJacks": return "Jumping Jacks"
        case "armRaises": return "Arm Raises"
        default: return appState.exerciseType
        }
    }
}

// MARK: - Helper Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ExerciseOption: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct QuickPresetButton: View {
    let value: Int
    let current: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(value)")
                .fontWeight(.medium)
                .frame(width: 50, height: 40)
        }
        .buttonStyle(.bordered)
        .tint(value == current ? .blue : .gray)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
        .environmentObject(OBSBOTManager())
}
