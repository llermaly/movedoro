import SwiftUI

/// Main settings view for OBSBOT camera control
struct CameraSettingsView: View {
    @EnvironmentObject var cameraManager: OBSBOTManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("OBSBOT Camera Control")
                        .font(.title)
                        .fontWeight(.bold)

                    Spacer()

                    // Connection status
                    HStack {
                        Circle()
                            .fill(cameraManager.isConnected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(cameraManager.isConnected ? "Connected" : "Disconnected")
                            .foregroundColor(cameraManager.isConnected ? .green : .red)

                        if let name = cameraManager.deviceName {
                            Text("(\(name))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.bottom, 10)

                Button("Scan for Cameras") {
                    cameraManager.scanForDevices()
                }
                .buttonStyle(.bordered)

                if cameraManager.isConnected {
                    Divider()

                    // Gimbal Controls
                    GroupBox("Gimbal Controls") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Spacer()
                                Button("Left") { cameraManager.moveGimbal(yaw: 0, pitch: -30, roll: 0) }
                                Button("Center") { cameraManager.moveGimbal(yaw: 0, pitch: 0, roll: 0) }
                                    .buttonStyle(.borderedProminent)
                                Button("Right") { cameraManager.moveGimbal(yaw: 0, pitch: 30, roll: 0) }
                                Spacer()
                            }
                            .buttonStyle(.bordered)

                            HStack {
                                Spacer()
                                Button("Up") { cameraManager.moveGimbal(yaw: -30, pitch: 0, roll: 0) }
                                Button("Down") { cameraManager.moveGimbal(yaw: 30, pitch: 0, roll: 0) }
                                Spacer()
                            }
                            .buttonStyle(.bordered)

                            Divider()

                            // Presets
                            Text("Presets")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                Spacer()
                                VStack {
                                    Button("Go Preset 1") { cameraManager.moveToPreset(id: 1) }
                                    Button("Save") { cameraManager.savePreset(id: 1, name: "Preset1") }
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)

                                VStack {
                                    Button("Go Preset 2") { cameraManager.moveToPreset(id: 2) }
                                    Button("Save") { cameraManager.savePreset(id: 2, name: "Preset2") }
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)

                                VStack {
                                    Button("Go Preset 3") { cameraManager.moveToPreset(id: 3) }
                                    Button("Save") { cameraManager.savePreset(id: 3, name: "Preset3") }
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                Spacer()
                            }
                        }
                    }

                    // Zoom & FOV
                    GroupBox("Zoom & Field of View") {
                        VStack(alignment: .leading, spacing: 12) {
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

                            Divider()

                            Text("Field of View")
                                .font(.subheadline)

                            HStack {
                                Button("Wide (86)") { cameraManager.setFOV(0) }
                                Button("Medium (78)") { cameraManager.setFOV(1) }
                                Button("Narrow (65)") { cameraManager.setFOV(2) }
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    // AI Tracking
                    GroupBox("AI Tracking") {
                        HStack {
                            Button("Enable") { cameraManager.enableAITracking(true) }
                                .tint(.green)
                            Button("Disable") { cameraManager.enableAITracking(false) }
                        }
                        .buttonStyle(.bordered)
                    }

                    // Focus Settings
                    GroupBox("Focus Settings") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Focus Mode")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Picker("Focus", selection: $cameraManager.focusMode) {
                                ForEach(OBSBOTFocusMode.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: cameraManager.focusMode) { _, newValue in
                                cameraManager.setFocusMode(newValue)
                            }

                            // Manual Focus Slider (only show when in manual mode)
                            if cameraManager.focusMode == .manual {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Manual Focus: \(cameraManager.manualFocusPosition)")
                                        .font(.caption)

                                    HStack {
                                        Text("Near")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)

                                        Slider(
                                            value: Binding(
                                                get: { Double(cameraManager.manualFocusPosition) },
                                                set: { cameraManager.setManualFocus(Int($0)) }
                                            ),
                                            in: 0...100,
                                            step: 1
                                        )

                                        Text("Far")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            // Face Focus Toggle
                            Toggle("Face Focus", isOn: $cameraManager.isFaceFocusEnabled)
                                .onChange(of: cameraManager.isFaceFocusEnabled) { _, newValue in
                                    cameraManager.setFaceFocus(newValue)
                                }
                        }
                    }

                    // HDR Settings
                    GroupBox("HDR") {
                        Toggle("Enable HDR", isOn: $cameraManager.isHDREnabled)
                            .onChange(of: cameraManager.isHDREnabled) { _, newValue in
                                cameraManager.setHDR(newValue)
                            }
                    }

                    // White Balance
                    GroupBox("White Balance") {
                        Picker("White Balance", selection: $cameraManager.whiteBalance) {
                            ForEach(OBSBOTWhiteBalance.allCases, id: \.self) { wb in
                                Text(wb.displayName).tag(wb)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: cameraManager.whiteBalance) { _, newValue in
                            cameraManager.setWhiteBalance(newValue)
                        }
                    }

                    // Media Mode
                    GroupBox("Media Mode") {
                        Picker("Media Mode", selection: .constant(OBSBOTMediaMode.normal)) {
                            ForEach(OBSBOTMediaMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: OBSBOTMediaMode.normal) { _, newValue in
                            cameraManager.setMediaMode(newValue)
                        }
                    }

                    // Refresh button
                    Button("Refresh Settings from Camera") {
                        cameraManager.refreshAllSettings()
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 10)
                }
            }
            .padding(30)
        }
        .frame(minWidth: 500, minHeight: 700)
    }
}

#Preview {
    CameraSettingsView()
        .environmentObject(OBSBOTManager())
}
