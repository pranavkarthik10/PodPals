//
//  PodPalsApp.swift
//  PodPals
//
//  Created by Pranav Karthik on 2023-11-05.
//

import Combine
import CoreMotion
import SwiftUI

@main
struct PodPalsApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState, accessAuthorized: $appState.accessAuthorized).fixedSize().preferredColorScheme(.dark)
        }.windowResizability(.contentSize)
    }
}

class AppState: ObservableObject {
    /** Corrected quaternion using calibration. */
    @Published var quaternion = CMQuaternion()

    @AppStorage("AppState.calibration") private var calibration: Data = .init()

    private var accessCheckTimer = Timer()
    @Published var accessAuthorized = HeadphoneMotionDetector.isAuthorized()

    var headphoneMotionDetector = HeadphoneMotionDetector()

    init() {
        headphoneMotionDetector.onUpdate = { [self] in
            quaternion = self.headphoneMotionDetector.correctedQuaternion
        }

        headphoneMotionDetector.start()

        // repeatedly check if access has been granted by the user
        if !HeadphoneMotionDetector.isAuthorized() {
            if HeadphoneMotionDetector.authorizationStatus == CMAuthorizationStatus.notDetermined {
                accessCheckTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    self.accessAuthorized = HeadphoneMotionDetector.isAuthorized()
                    if HeadphoneMotionDetector.authorizationStatus != CMAuthorizationStatus.notDetermined {
                        self.accessCheckTimer.invalidate()
                    }
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {}

    func applicationWillTerminate(_: Notification) {}

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
}
