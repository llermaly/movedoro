import SwiftUI

@main
struct OBSBOTCameraControlApp: App {
    @StateObject private var cameraManager = OBSBOTManager()

    var body: some Scene {
        WindowGroup {
            CameraSettingsView()
                .environmentObject(cameraManager)
                .onAppear {
                    cameraManager.initialize()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
