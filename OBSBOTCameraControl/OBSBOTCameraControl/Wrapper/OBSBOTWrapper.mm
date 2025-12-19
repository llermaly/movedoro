//
//  OBSBOTWrapper.mm
//  OBSBOTCameraControl
//
//  Objective-C++ implementation that bridges to the OBSBOT C++ SDK
//

#import "OBSBOTWrapper.h"
#include <dev/devs.hpp>
#include <vector>
#include <string>
#include <memory>

// Store device serial numbers
static std::vector<std::string> g_deviceSNs;
static std::shared_ptr<Device> g_selectedDevice;
static OBSBOTDeviceChangedCallback g_deviceChangedCallback = nil;

// C++ callback that gets called when devices connect/disconnect
void onDeviceChanged(std::string dev_sn, bool connected, void *param) {
    @autoreleasepool {
        auto it = std::find(g_deviceSNs.begin(), g_deviceSNs.end(), dev_sn);

        if (connected) {
            if (it == g_deviceSNs.end()) {
                g_deviceSNs.push_back(dev_sn);
            }
        } else {
            if (it != g_deviceSNs.end()) {
                g_deviceSNs.erase(it);
            }
        }

        // Call Swift callback on main thread
        if (g_deviceChangedCallback) {
            NSString *deviceSN = [NSString stringWithUTF8String:dev_sn.c_str()];
            dispatch_async(dispatch_get_main_queue(), ^{
                g_deviceChangedCallback(deviceSN, connected);
            });
        }
    }
}

// Silent log handler to suppress SDK debug output
void silentLogHandler(int32_t lvl, const char *msg, va_list args, void *p) {
    // Only show errors
    if (lvl <= DEV_ERROR) {
        vprintf(msg, args);
        printf("\n");
    }
}

@implementation OBSBOTWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        g_deviceSNs.clear();
        g_selectedDevice = nullptr;
    }
    return self;
}

- (void)initialize {
    // Silence debug logs
    dev_set_log_handler(silentLogHandler, nullptr);

    // Register device changed callback
    Devices::get().setDevChangedCallback(onDeviceChanged, nullptr);

    // Disable mDNS scanning (we only want USB devices)
    Devices::get().setEnableMdnsScan(false);
}

- (void)scanForDevices {
    // Give the SDK time to detect devices
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        auto devList = Devices::get().getDevList();
        g_deviceSNs.clear();

        for (auto &device : devList) {
            g_deviceSNs.push_back(device->devSn());

            // Notify about existing devices
            if (g_deviceChangedCallback) {
                NSString *deviceSN = [NSString stringWithUTF8String:device->devSn().c_str()];
                g_deviceChangedCallback(deviceSN, YES);
            }
        }
    });
}

- (NSInteger)deviceCount {
    return static_cast<NSInteger>(g_deviceSNs.size());
}

- (nullable NSString *)deviceNameAtIndex:(NSInteger)index {
    if (index < 0 || index >= static_cast<NSInteger>(g_deviceSNs.size())) {
        return nil;
    }

    auto device = Devices::get().getDevBySn(g_deviceSNs[index]);
    if (device) {
        return [NSString stringWithUTF8String:device->devName().c_str()];
    }
    return nil;
}

- (BOOL)selectDeviceAtIndex:(NSInteger)index {
    if (index < 0 || index >= static_cast<NSInteger>(g_deviceSNs.size())) {
        return NO;
    }

    g_selectedDevice = Devices::get().getDevBySn(g_deviceSNs[index]);
    return g_selectedDevice != nullptr;
}

- (void)setDeviceChangedCallback:(OBSBOTDeviceChangedCallback)callback {
    g_deviceChangedCallback = [callback copy];
}

#pragma mark - Gimbal Control

- (void)moveGimbalWithYaw:(float)yaw pitch:(float)pitch roll:(float)roll {
    if (!g_selectedDevice) return;

    // Check if device supports gimbal control (Tiny2, TailAir)
    auto productType = g_selectedDevice->productType();
    if (productType == ObsbotProdTiny2 || productType == ObsbotProdTailAir) {
        g_selectedDevice->aiSetGimbalMotorAngleR(yaw, pitch, roll);
    }
}

- (void)moveGimbalBySpeedWithYawSpeed:(float)yawSpeed pitchSpeed:(float)pitchSpeed {
    if (!g_selectedDevice) return;

    g_selectedDevice->aiSetGimbalSpeedCtrlR(static_cast<int>(yawSpeed),
                                             static_cast<int>(pitchSpeed),
                                             60); // roll speed
}

#pragma mark - AI Tracking

- (void)enableAITracking:(BOOL)enable {
    if (!g_selectedDevice) return;

    auto productType = g_selectedDevice->productType();

    if (productType == ObsbotProdTiny2) {
        if (enable) {
            g_selectedDevice->cameraSetAiModeU(Device::AiWorkModeHuman, Device::AiSubModeUpperBody);
        } else {
            g_selectedDevice->cameraSetAiModeU(Device::AiWorkModeNone);
        }
    } else if (productType == ObsbotProdTiny || productType == ObsbotProdTiny4k) {
        g_selectedDevice->aiSetTargetSelectR(enable);
    } else if (productType == ObsbotProdTailAir) {
        g_selectedDevice->aiSetAiTrackModeEnabledR(Device::AiTrackHumanNormal, enable);
    }
}

#pragma mark - Camera Control

- (void)setZoom:(float)level {
    if (!g_selectedDevice) return;

    g_selectedDevice->cameraSetZoomAbsoluteR(level);
}

- (void)setFov:(int32_t)fovType {
    if (!g_selectedDevice) return;

    Device::FovType fov;
    switch (fovType) {
        case 0: fov = Device::FovType86; break;   // Wide 86
        case 1: fov = Device::FovType78; break;   // Medium 78
        case 2: fov = Device::FovType65; break;   // Narrow 65
        default: fov = Device::FovType86; break;
    }

    g_selectedDevice->cameraSetFovU(fov);
}

#pragma mark - Focus Control

- (void)setAutoFocusMode:(int32_t)focusMode {
    if (!g_selectedDevice) return;

    Device::DevAutoFocusType afType;
    switch (focusMode) {
        case 0: afType = Device::DevAutoFocusAutoSelect; break;
        case 1: afType = Device::DevAutoFocusAFC; break;  // Continuous AF
        case 2: afType = Device::DevAutoFocusAFS; break;  // Single AF
        case 3: afType = Device::DevAutoFocusMF; break;   // Manual
        default: afType = Device::DevAutoFocusAutoSelect; break;
    }

    g_selectedDevice->cameraSetAutoFocusModeR(afType);
}

- (int32_t)getAutoFocusMode {
    if (!g_selectedDevice) return -1;

    Device::DevAutoFocusType afType;
    if (g_selectedDevice->cameraGetAutoFocusModeR(afType) == 0) {
        switch (afType) {
            case Device::DevAutoFocusAutoSelect: return 0;
            case Device::DevAutoFocusAFC: return 1;
            case Device::DevAutoFocusAFS: return 2;
            case Device::DevAutoFocusMF: return 3;
            default: return 0;
        }
    }
    return -1;
}

- (void)setManualFocusPosition:(int32_t)position {
    if (!g_selectedDevice) return;

    // Clamp to valid range 0-100
    int32_t clampedPos = std::max(0, std::min(100, position));
    g_selectedDevice->cameraSetFocusPosR(clampedPos);
}

- (int32_t)getManualFocusPosition {
    if (!g_selectedDevice) return -1;

    int32_t focusPos = 0;
    if (g_selectedDevice->cameraGetFocusPosR(focusPos) == 0) {
        return focusPos;
    }
    return -1;
}

- (void)setFaceFocus:(BOOL)enable {
    if (!g_selectedDevice) return;

    g_selectedDevice->cameraSetFaceFocusR(enable);
}

#pragma mark - HDR Control

- (void)setHDR:(BOOL)enable {
    if (!g_selectedDevice) return;

    g_selectedDevice->cameraSetWdrR(enable);
}

- (BOOL)getHDR {
    if (!g_selectedDevice) return NO;

    int32_t enabled = 0;
    if (g_selectedDevice->cameraGetWdrR(enabled) == 0) {
        return enabled != 0;
    }
    return NO;
}

#pragma mark - White Balance

- (void)setWhiteBalance:(int32_t)wbType manualValue:(int32_t)manualValue {
    if (!g_selectedDevice) return;

    Device::DevWhiteBalanceType wb;
    switch (wbType) {
        case 0: wb = Device::DevWhiteBalanceAuto; break;
        case 1: wb = Device::DevWhiteBalanceDaylight; break;
        case 2: wb = Device::DevWhiteBalanceFluorescent; break;
        case 3: wb = Device::DevWhiteBalanceTungsten; break;
        case 4: wb = Device::DevWhiteBalanceCloudy; break;
        case 255: wb = Device::DevWhiteBalanceManual; break;
        default: wb = Device::DevWhiteBalanceAuto; break;
    }

    g_selectedDevice->cameraSetWhiteBalanceR(wb, manualValue);
}

- (int32_t)getWhiteBalanceType {
    if (!g_selectedDevice) return -1;

    Device::DevWhiteBalanceType wbType;
    int32_t param;
    if (g_selectedDevice->cameraGetWhiteBalanceR(wbType, param) == 0) {
        switch (wbType) {
            case Device::DevWhiteBalanceAuto: return 0;
            case Device::DevWhiteBalanceDaylight: return 1;
            case Device::DevWhiteBalanceFluorescent: return 2;
            case Device::DevWhiteBalanceTungsten: return 3;
            case Device::DevWhiteBalanceCloudy: return 4;
            case Device::DevWhiteBalanceManual: return 255;
            default: return 0;
        }
    }
    return -1;
}

#pragma mark - Media Mode

- (void)setMediaMode:(int32_t)mode {
    if (!g_selectedDevice) return;

    Device::MediaMode mediaMode;
    switch (mode) {
        case 0: mediaMode = Device::MediaModeNormal; break;
        case 1: mediaMode = Device::MediaModeBackground; break;
        case 2: mediaMode = Device::MediaModeAutoFrame; break;
        default: mediaMode = Device::MediaModeNormal; break;
    }

    g_selectedDevice->cameraSetMediaModeU(mediaMode);
}

#pragma mark - Presets

- (void)savePresetWithId:(int32_t)presetId name:(NSString *)name {
    if (!g_selectedDevice) return;

    Device::PresetPosInfo presetInfo;
    presetInfo.id = presetId;

    const char *nameStr = [name UTF8String];
    size_t nameLen = strlen(nameStr);
    memcpy(presetInfo.name, nameStr, std::min(nameLen, sizeof(presetInfo.name) - 1));
    presetInfo.name_len = static_cast<uint8_t>(nameLen);

    // Get current gimbal position
    Device::AiGimbalStateInfo stateInfo;
    g_selectedDevice->aiGetGimbalStateR(&stateInfo);

    presetInfo.yaw = stateInfo.yaw_motor;
    presetInfo.pitch = stateInfo.pitch_motor;
    presetInfo.roll = stateInfo.roll_motor;
    presetInfo.zoom = 1.0f;

    g_selectedDevice->aiAddGimbalPresetR(&presetInfo);
}

- (void)moveToPresetWithId:(int32_t)presetId {
    if (!g_selectedDevice) return;

    g_selectedDevice->aiTrgGimbalPresetR(presetId);
}

@end
