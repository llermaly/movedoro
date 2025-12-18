import SwiftUI
import AVFoundation

/// Fullscreen exercise overlay that blocks the screen during breaks
struct ExerciseOverlayView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cameraManager: OBSBOTManager
    @StateObject private var cameraCapture = CameraCapture()
    @StateObject private var poseDetector = PoseDetector()
    @StateObject private var photoManager = SessionPhotoManager()

    @State private var showPoseOverlay = true
    @State private var isSettingUp = true
    @State private var hasAnnouncedCompletion = false

    var repsRequired: Int { appState.repsRequired }
    var repsCompleted: Int { poseDetector.exerciseCount }
    var isComplete: Bool { repsCompleted >= repsRequired }

    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Break Time!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Complete your exercises to continue working")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    // Rep progress
                    HStack(spacing: 8) {
                        Text("\(repsCompleted)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(isComplete ? .green : .white)

                        Text("/ \(repsRequired)")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)

                // Camera preview
                ZStack {
                    if cameraCapture.isCapturing {
                        ZStack {
                            CameraPreviewView(cameraCapture: cameraCapture)

                            if showPoseOverlay {
                                PoseOverlayView(pose: poseDetector.currentPose, imageSize: CGSize(width: 800, height: 600))
                            }
                        }
                        .frame(maxWidth: 800, maxHeight: 600)
                        .cornerRadius(16)
                    } else {
                        // Camera not running - show placeholder with start button
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.3))
                            .frame(maxWidth: 800, maxHeight: 600)
                            .overlay(
                                VStack(spacing: 20) {
                                    if isSettingUp {
                                        ProgressView()
                                            .scaleEffect(2)
                                            .tint(.white)
                                        Text("Starting camera...")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.gray)

                                        Text("Camera is off")
                                            .font(.title2)
                                            .foregroundColor(.white)

                                        Button(action: { startCamera() }) {
                                            Label("Start Camera", systemImage: "camera")
                                                .font(.title3)
                                                .padding()
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.blue)
                                    }
                                }
                            )
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isComplete ? Color.green : Color.blue, lineWidth: 4)
                )

                // Status bar
                HStack(spacing: 30) {
                    // Camera status
                    HStack {
                        Circle()
                            .fill(cameraCapture.isCapturing ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(cameraCapture.isCapturing ? "Camera on" : "Camera off")
                            .foregroundColor(cameraCapture.isCapturing ? .green : .red)
                    }

                    if cameraCapture.isCapturing {
                        Divider()
                            .frame(height: 20)
                            .background(Color.gray)

                        // Pose status
                        HStack {
                            Circle()
                                .fill(poseDetector.isPersonDetected ? Color.green : Color.orange)
                                .frame(width: 12, height: 12)
                            Text(poseDetector.poseDescription)
                                .foregroundColor(.white)
                        }

                        // Exercise state (if calibrated)
                        if poseDetector.currentExercise == .sitToStand && poseDetector.isCalibrated {
                            Divider()
                                .frame(height: 20)
                                .background(Color.gray)

                            HStack {
                                Circle()
                                    .fill(stateColor(for: poseDetector.exerciseState))
                                    .frame(width: 12, height: 12)
                                Text(poseDetector.exerciseState.rawValue)
                                    .fontWeight(.medium)
                                    .foregroundColor(stateColor(for: poseDetector.exerciseState))
                            }
                        }

                        // Last rep score
                        if poseDetector.lastRepScore > 0 {
                            Divider()
                                .frame(height: 20)
                                .background(Color.gray)

                            HStack(spacing: 4) {
                                Text("Last:")
                                    .foregroundColor(.gray)
                                Text("\(poseDetector.lastRepScore)%")
                                    .fontWeight(.bold)
                                    .foregroundColor(scoreColor(poseDetector.lastRepScore))
                            }
                        }
                    }

                    Spacer()

                    // Skeleton toggle
                    if cameraCapture.isCapturing {
                        Toggle("Skeleton", isOn: $showPoseOverlay)
                            .toggleStyle(.button)
                            .tint(.gray)
                    }

                    // Manual camera start if not capturing
                    if !cameraCapture.isCapturing && !isSettingUp {
                        Button(action: { startCamera() }) {
                            Label("Start Camera", systemImage: "camera")
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                }
                .padding(.horizontal, 40)

                // Completion message or instructions
                if isComplete {
                    VStack(spacing: 15) {
                        Text("Great job!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)

                        Button(action: { completeExercise() }) {
                            Label("Continue Working", systemImage: "arrow.right.circle.fill")
                                .font(.title2)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .controlSize(.large)
                    }
                    .padding(.top, 10)
                } else if cameraCapture.isCapturing {
                    // Show instructions based on calibration status
                    if poseDetector.currentExercise == .sitToStand {
                        if !poseDetector.isCalibrated {
                            VStack(spacing: 12) {
                                Text("Calibration needed for accurate tracking")
                                    .foregroundColor(.orange)

                                if poseDetector.calibrationState != .notCalibrated &&
                                   poseDetector.calibrationState != .calibrated {
                                    Text(poseDetector.calibrationMessage)
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                        .padding()
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(12)

                                    Button("Cancel") {
                                        poseDetector.cancelCalibration()
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                } else {
                                    Button("Calibrate Now") {
                                        poseDetector.startCalibration()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.purple)
                                    .controlSize(.large)
                                }
                            }
                        } else {
                            Text("Complete \(repsRequired - repsCompleted) more reps to continue")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    } else {
                        Text("Complete \(repsRequired - repsCompleted) more reps to continue")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                Spacer()

                // DEBUG: Skip button
                #if DEBUG
                HStack {
                    Button(action: { completeExercise() }) {
                        Label("DEBUG: Skip Exercise", systemImage: "forward.end.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)

                    if !cameraCapture.isCapturing {
                        Button(action: { startCamera() }) {
                            Label("DEBUG: Force Start Camera", systemImage: "camera")
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                }
                .padding(.bottom, 20)
                #endif
            }
        }
        .onAppear {
            setupExercise()
        }
        .onDisappear {
            cameraCapture.stopCapture()
        }
        .onChange(of: isComplete) { completed in
            if completed && !hasAnnouncedCompletion {
                hasAnnouncedCompletion = true
                // Wait for the last rep speech to finish before announcing completion
                poseDetector.speakAfterCurrent("Great job! All reps complete. Click continue to get back to work.")
            }
        }
    }

    private func setupExercise() {
        isSettingUp = true
        hasAnnouncedCompletion = false

        // Set exercise type from settings
        let exerciseType: PoseDetector.ExerciseType
        switch appState.exerciseType {
        case "sitToStand": exerciseType = .sitToStand
        case "squats": exerciseType = .squats
        case "jumpingJacks": exerciseType = .jumpingJacks
        case "armRaises": exerciseType = .armRaises
        default: exerciseType = .sitToStand
        }
        poseDetector.setExercise(exerciseType)

        // Announce break start
        let exerciseName = exerciseType.rawValue
        poseDetector.speakAfterCurrent("Break time! Complete \(appState.repsRequired) \(exerciseName) reps to continue working.")

        // Setup callbacks
        poseDetector.onCapturePhoto = { [weak photoManager] repNumber, position in
            guard let photoManager = photoManager,
                  let image = cameraCapture.capturePhoto() else { return }
            let pos: ExercisePhoto.Position = position == "sitting" ? .sitting : .standing
            photoManager.capturePhoto(image: image, repNumber: repNumber, position: pos)
        }

        poseDetector.onRepCompleted = { [weak photoManager] repNumber, score in
            photoManager?.updateScore(forRep: repNumber, score: score)
        }

        // Start photo session
        photoManager.startSession()

        // Move camera to exercise preset if OBSBOT connected
        if cameraManager.isConnected {
            cameraManager.moveToPreset(id: 2) // Exercise preset
        }

        // Start camera with slight delay to ensure view is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            startCamera()
            isSettingUp = false
        }
    }

    private func startCamera() {
        cameraCapture.loadAvailableCameras()
        cameraCapture.poseDetector = poseDetector
        cameraCapture.startCapture()
    }

    private func completeExercise() {
        cameraCapture.stopCapture()

        // Move camera back to meeting preset
        if cameraManager.isConnected {
            cameraManager.moveToPreset(id: 1) // Meeting preset
        }

        appState.completeExercise()
    }

    private func stateColor(for state: PoseDetector.ExerciseState) -> Color {
        switch state {
        case .standing: return .green
        case .goingDown: return .orange
        case .holdingSit: return .yellow
        case .sitting: return .blue
        case .goingUp: return .purple
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 90...100: return .green
        case 70..<90: return .blue
        case 50..<70: return .orange
        default: return .red
        }
    }
}

#Preview {
    ExerciseOverlayView()
        .environmentObject(AppState())
        .environmentObject(OBSBOTManager())
}
