import Foundation
import Combine

/// Focus mode options for OBSBOT camera
enum OBSBOTFocusMode: Int, CaseIterable {
    case auto = 0
    case continuousAF = 1
    case singleAF = 2
    case manual = 3

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .continuousAF: return "Continuous AF"
        case .singleAF: return "Single AF"
        case .manual: return "Manual"
        }
    }
}

/// White balance options for OBSBOT camera
enum OBSBOTWhiteBalance: Int, CaseIterable {
    case auto = 0
    case daylight = 1
    case fluorescent = 2
    case tungsten = 3
    case cloudy = 4

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .daylight: return "Daylight"
        case .fluorescent: return "Fluorescent"
        case .tungsten: return "Tungsten"
        case .cloudy: return "Cloudy"
        }
    }
}

/// Media mode options for OBSBOT camera
enum OBSBOTMediaMode: Int, CaseIterable {
    case normal = 0
    case virtualBackground = 1
    case autoFrame = 2

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .virtualBackground: return "Virtual Background"
        case .autoFrame: return "Auto Frame"
        }
    }
}

/// Swift manager class that wraps the OBSBOT SDK
class OBSBOTManager: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var deviceName: String?
    @Published var zoomLevel: Double = 1.0
    @Published var isAITrackingEnabled: Bool = false

    // Camera settings
    @Published var focusMode: OBSBOTFocusMode = .auto
    @Published var manualFocusPosition: Int = 50
    @Published var isFaceFocusEnabled: Bool = false
    @Published var isHDREnabled: Bool = false
    @Published var whiteBalance: OBSBOTWhiteBalance = .auto

    private var wrapper: OBSBOTWrapper?

    init() {
        wrapper = OBSBOTWrapper()
    }

    /// Initialize the SDK and start scanning for devices
    func initialize() {
        wrapper?.initialize()

        // Set up device change callback
        wrapper?.setDeviceChangedCallback { [weak self] deviceSN, connected in
            DispatchQueue.main.async {
                self?.isConnected = connected
                if connected {
                    self?.deviceName = deviceSN
                    // Auto-select first device
                    self?.wrapper?.selectDevice(at: 0)
                } else {
                    self?.deviceName = nil
                }
            }
        }

        // Start scanning
        scanForDevices()
    }

    /// Scan for connected OBSBOT devices
    func scanForDevices() {
        wrapper?.scanForDevices()

        // Check if devices are already connected
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if let count = self?.wrapper?.deviceCount(), count > 0 {
                self?.isConnected = true
                self?.deviceName = self?.wrapper?.deviceName(at: 0)
                self?.wrapper?.selectDevice(at: 0)
            }
        }
    }

    /// Move the gimbal to specified angles
    func moveGimbal(yaw: Float, pitch: Float, roll: Float) {
        guard isConnected else { return }
        wrapper?.moveGimbal(withYaw: yaw, pitch: pitch, roll: roll)
    }

    /// Enable or disable AI tracking
    func enableAITracking(_ enable: Bool) {
        guard isConnected else { return }
        wrapper?.enableAITracking(enable)
        isAITrackingEnabled = enable
    }

    /// Set zoom level (1.0 - 2.0, normalized range per SDK docs)
    func setZoom(_ level: Double) {
        guard isConnected else { return }
        let clampedLevel = min(max(level, 1.0), 2.0)
        wrapper?.setZoom(Float(clampedLevel))
        DispatchQueue.main.async {
            self.zoomLevel = clampedLevel
        }
    }

    /// Set field of view
    /// - Parameter fovType: 0=Wide(86), 1=Medium(78), 2=Narrow(65)
    func setFOV(_ fovType: Int) {
        guard isConnected else { return }
        wrapper?.setFov(Int32(fovType))
    }

    /// Move gimbal by speed (for continuous movement)
    func moveGimbalBySpeed(yawSpeed: Float, pitchSpeed: Float) {
        guard isConnected else { return }
        wrapper?.moveGimbalBySpeed(withYawSpeed: yawSpeed, pitchSpeed: pitchSpeed)
    }

    /// Stop gimbal movement
    func stopGimbal() {
        guard isConnected else { return }
        wrapper?.moveGimbalBySpeed(withYawSpeed: 0, pitchSpeed: 0)
    }

    /// Save current position as preset
    func savePreset(id: Int, name: String) {
        guard isConnected else { return }
        wrapper?.savePreset(withId: Int32(id), name: name)
    }

    /// Move to saved preset position
    func moveToPreset(id: Int) {
        guard isConnected else { return }
        wrapper?.moveToPreset(withId: Int32(id))
    }

    // MARK: - Focus Control

    /// Set the auto focus mode
    func setFocusMode(_ mode: OBSBOTFocusMode) {
        guard isConnected else { return }
        wrapper?.setAutoFocusMode(Int32(mode.rawValue))
        DispatchQueue.main.async {
            self.focusMode = mode
        }
    }

    /// Get current focus mode from device
    func refreshFocusMode() {
        guard isConnected else { return }
        let mode = wrapper?.getAutoFocusMode() ?? 0
        DispatchQueue.main.async {
            self.focusMode = OBSBOTFocusMode(rawValue: Int(mode)) ?? .auto
        }
    }

    /// Set manual focus position (0-100)
    func setManualFocus(_ position: Int) {
        guard isConnected else { return }
        let clamped = min(max(position, 0), 100)
        wrapper?.setManualFocusPosition(Int32(clamped))
        DispatchQueue.main.async {
            self.manualFocusPosition = clamped
        }
    }

    /// Get current manual focus position
    func refreshManualFocusPosition() {
        guard isConnected else { return }
        let pos = wrapper?.getManualFocusPosition() ?? 50
        DispatchQueue.main.async {
            self.manualFocusPosition = Int(pos)
        }
    }

    /// Enable or disable face focus
    func setFaceFocus(_ enable: Bool) {
        guard isConnected else { return }
        wrapper?.setFaceFocus(enable)
        DispatchQueue.main.async {
            self.isFaceFocusEnabled = enable
        }
    }

    // MARK: - HDR Control

    /// Enable or disable HDR
    func setHDR(_ enable: Bool) {
        guard isConnected else { return }
        wrapper?.setHDR(enable)
        DispatchQueue.main.async {
            self.isHDREnabled = enable
        }
    }

    /// Refresh HDR state from device
    func refreshHDRState() {
        guard isConnected else { return }
        let enabled = wrapper?.getHDR() ?? false
        DispatchQueue.main.async {
            self.isHDREnabled = enabled
        }
    }

    // MARK: - White Balance

    /// Set white balance mode
    func setWhiteBalance(_ mode: OBSBOTWhiteBalance, manualValue: Int = 5000) {
        guard isConnected else { return }
        wrapper?.setWhiteBalance(Int32(mode.rawValue), manualValue: Int32(manualValue))
        DispatchQueue.main.async {
            self.whiteBalance = mode
        }
    }

    /// Refresh white balance from device
    func refreshWhiteBalance() {
        guard isConnected else { return }
        let wbType = wrapper?.getWhiteBalanceType() ?? 0
        DispatchQueue.main.async {
            self.whiteBalance = OBSBOTWhiteBalance(rawValue: Int(wbType)) ?? .auto
        }
    }

    // MARK: - Media Mode

    /// Set media mode
    func setMediaMode(_ mode: OBSBOTMediaMode) {
        guard isConnected else { return }
        wrapper?.setMediaMode(Int32(mode.rawValue))
    }

    // MARK: - Refresh All Settings

    /// Refresh all camera settings from device
    func refreshAllSettings() {
        refreshFocusMode()
        refreshManualFocusPosition()
        refreshHDRState()
        refreshWhiteBalance()
    }
}
