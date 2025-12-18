import SwiftUI
import AVFoundation

/// Advanced settings for camera, calibration, and OBSBOT controls
struct AdvancedSettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cameraManager: OBSBOTManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var cameraCapture = CameraCapture()
    @StateObject private var poseDetector = PoseDetector()

    @State private var showPoseOverlay = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Advanced Settings")
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

            HStack(spacing: 0) {
                // Left: Camera Preview
                VStack {
                    ZStack {
                        CameraPreviewView(cameraCapture: cameraCapture)
                            .frame(width: 400, height: 300)

                        if showPoseOverlay {
                            PoseOverlayView(pose: poseDetector.currentPose, imageSize: CGSize(width: 400, height: 300))
                                .frame(width: 400, height: 300)
                        }
                    }
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                    // Camera controls
                    HStack {
                        if !cameraCapture.availableCameras.isEmpty {
                            Picker("Camera", selection: Binding(
                                get: { cameraCapture.selectedCamera },
                                set: { if let cam = $0 { cameraCapture.selectCamera(cam) } }
                            )) {
                                ForEach(cameraCapture.availableCameras, id: \.uniqueID) { camera in
                                    Text(camera.localizedName).tag(camera as AVCaptureDevice?)
                                }
                            }
                            .frame(width: 200)
                        }

                        Button(cameraCapture.isCapturing ? "Stop" : "Start") {
                            if cameraCapture.isCapturing {
                                cameraCapture.stopCapture()
                            } else {
                                cameraCapture.poseDetector = poseDetector
                                cameraCapture.startCapture()
                            }
                        }
                        .buttonStyle(.bordered)

                        Toggle("Skeleton", isOn: $showPoseOverlay)
                            .toggleStyle(.button)
                    }
                    .padding(.top, 10)

                    // Pose status
                    if cameraCapture.isCapturing {
                        HStack {
                            Circle()
                                .fill(poseDetector.isPersonDetected ? Color.green : Color.orange)
                                .frame(width: 10, height: 10)
                            Text(poseDetector.poseDescription)
                                .font(.caption)
                        }
                        .padding(.top, 5)
                    }
                }
                .padding()

                Divider()

                // Right: Controls
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // OBSBOT Section
                        GroupBox("OBSBOT Camera") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Circle()
                                        .fill(cameraManager.isConnected ? Color.green : Color.red)
                                        .frame(width: 10, height: 10)
                                    Text(cameraManager.isConnected ? "Connected" : "Disconnected")
                                        .foregroundColor(cameraManager.isConnected ? .green : .red)

                                    if let name = cameraManager.deviceName {
                                        Text("(\(name))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Button("Scan for Cameras") {
                                    cameraManager.scanForDevices()
                                    cameraCapture.loadAvailableCameras()
                                }
                                .buttonStyle(.bordered)

                                if cameraManager.isConnected {
                                    Divider()

                                    // Gimbal controls
                                    Text("Gimbal")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    HStack {
                                        Button("Left") { cameraManager.moveGimbal(yaw: 0, pitch: -30, roll: 0) }
                                        Button("Center") { cameraManager.moveGimbal(yaw: 0, pitch: 0, roll: 0) }
                                        Button("Right") { cameraManager.moveGimbal(yaw: 0, pitch: 30, roll: 0) }
                                    }
                                    .buttonStyle(.bordered)

                                    HStack {
                                        Button("Up") { cameraManager.moveGimbal(yaw: -30, pitch: 0, roll: 0) }
                                        Button("Down") { cameraManager.moveGimbal(yaw: 30, pitch: 0, roll: 0) }
                                    }
                                    .buttonStyle(.bordered)

                                    Divider()

                                    // Presets
                                    Text("Presets")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    HStack {
                                        VStack {
                                            Button("Go Meeting") { cameraManager.moveToPreset(id: 1) }
                                            Button("Save") { cameraManager.savePreset(id: 1, name: "Meeting") }
                                                .font(.caption)
                                        }
                                        .buttonStyle(.bordered)

                                        VStack {
                                            Button("Go Exercise") { cameraManager.moveToPreset(id: 2) }
                                            Button("Save") { cameraManager.savePreset(id: 2, name: "Exercise") }
                                                .font(.caption)
                                        }
                                        .buttonStyle(.bordered)
                                    }

                                    Divider()

                                    // Zoom & FOV
                                    Text("Zoom: \(String(format: "%.1fx", cameraManager.zoomLevel))")
                                        .font(.subheadline)

                                    Slider(value: $cameraManager.zoomLevel, in: 1.0...2.0, step: 0.1)
                                        .onChange(of: cameraManager.zoomLevel) { _, newValue in
                                            cameraManager.setZoom(newValue)
                                        }

                                    HStack {
                                        Button("1x") { cameraManager.setZoom(1.0) }
                                        Button("1.5x") { cameraManager.setZoom(1.5) }
                                        Button("2x") { cameraManager.setZoom(2.0) }
                                    }
                                    .buttonStyle(.bordered)

                                    Text("Field of View")
                                        .font(.subheadline)

                                    HStack {
                                        Button("Wide") { cameraManager.setFOV(0) }
                                        Button("Medium") { cameraManager.setFOV(1) }
                                        Button("Narrow") { cameraManager.setFOV(2) }
                                    }
                                    .buttonStyle(.bordered)

                                    Divider()

                                    // AI Tracking
                                    Text("AI Tracking")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    HStack {
                                        Button("Enable") { cameraManager.enableAITracking(true) }
                                            .tint(.green)
                                        Button("Disable") { cameraManager.enableAITracking(false) }
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }

                        // Calibration Section
                        GroupBox("Exercise Calibration") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Circle()
                                        .fill(poseDetector.isCalibrated ? Color.green : Color.orange)
                                        .frame(width: 10, height: 10)
                                    Text(poseDetector.isCalibrated ? "Calibrated" : "Not Calibrated")
                                        .foregroundColor(poseDetector.isCalibrated ? .green : .orange)
                                }

                                if poseDetector.calibrationState != .notCalibrated &&
                                   poseDetector.calibrationState != .calibrated {
                                    Text(poseDetector.calibrationMessage)
                                        .font(.caption)
                                        .foregroundColor(.blue)

                                    Button("Cancel") {
                                        poseDetector.cancelCalibration()
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                } else {
                                    Button(poseDetector.isCalibrated ? "Re-Calibrate" : "Calibrate") {
                                        if !cameraCapture.isCapturing {
                                            cameraCapture.poseDetector = poseDetector
                                            cameraCapture.startCapture()
                                        }
                                        poseDetector.startCalibration()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.purple)
                                }

                                if poseDetector.isCalibrated {
                                    Text("Sit Y: \(String(format: "%.3f", poseDetector.sittingHipY))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("Stand Y: \(String(format: "%.3f", poseDetector.standingHipY))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Button("Clear Calibration") {
                                        poseDetector.clearCalibration()
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                    .font(.caption)
                                }
                            }
                        }

                        // Debug Info
                        #if DEBUG
                        GroupBox("Debug Info") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Exercise State: \(poseDetector.exerciseState.rawValue)")
                                    .font(.caption)
                                Text("Rep Count: \(poseDetector.exerciseCount)")
                                    .font(.caption)
                                Text("Last Score: \(poseDetector.lastRepScore)%")
                                    .font(.caption)

                                if let pose = poseDetector.currentPose, let hipY = pose.hipY {
                                    Text("Current Hip Y: \(String(format: "%.3f", hipY))")
                                        .font(.caption)
                                }
                            }
                        }
                        #endif
                    }
                    .padding()
                }
                .frame(width: 350)
            }
        }
        .frame(width: 800, height: 600)
        .onDisappear {
            cameraCapture.stopCapture()
        }
    }
}

#Preview {
    AdvancedSettingsView()
        .environmentObject(AppState())
        .environmentObject(OBSBOTManager())
}
