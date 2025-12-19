# OBSBOT Camera Control

A standalone macOS app for controlling OBSBOT cameras (Tiny2, Tiny, Tiny4k, TailAir).

## Features

- Device connection and management
- Gimbal control (pan, tilt, roll)
- 3 position presets
- Zoom control (1.0x - 2.0x)
- Field of View selection (Wide/Medium/Narrow)
- AI Tracking toggle
- Focus control (Auto, Continuous AF, Single AF, Manual)
- Face Focus
- HDR/WDR control
- White Balance presets
- Media Mode selection

## Setting up the Xcode Project

1. Open Xcode and create a new project:
   - Select "macOS" -> "App"
   - Product Name: `OBSBOTCameraControl`
   - Organization Identifier: your identifier
   - Interface: SwiftUI
   - Language: Swift

2. Delete the default files created by Xcode (ContentView.swift, OBSBOTCameraControlApp.swift)

3. Add the existing source files:
   - Drag the `OBSBOTCameraControl` folder contents into the project
   - Make sure "Copy items if needed" is checked

4. Configure the bridging header:
   - Go to Build Settings
   - Search for "Objective-C Bridging Header"
   - Set it to: `$(SRCROOT)/OBSBOTCameraControl/OBSBOTCameraControl-Bridging-Header.h`

5. Configure the SDK library:
   - Go to Build Settings -> Library Search Paths
   - Add: `$(SRCROOT)/OBSBOTCameraControl/SDK`
   - Go to Build Settings -> Header Search Paths
   - Add: `$(SRCROOT)/OBSBOTCameraControl/SDK/include`
   - Go to Build Phases -> Link Binary With Libraries
   - Add `libdev.dylib` from the SDK folder

6. Configure the library for runtime:
   - Go to Build Phases
   - Add a "Copy Files" phase
   - Destination: Frameworks
   - Add `libdev.dylib`

7. Set deployment target:
   - Set macOS Deployment Target to 14.0 or higher

8. Build and run!

## Requirements

- macOS 14.0+
- OBSBOT camera connected via USB
- libdev SDK v2.1.0_7 (included)

## Supported Devices

- OBSBOT Tiny 2
- OBSBOT Tiny
- OBSBOT Tiny 4K
- OBSBOT Tail Air
