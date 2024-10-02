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
    @State var enabled: Bool = true
    
    
    var body: some Scene {
//        WindowGroup {
//
//        }.windowResizability(.contentSize)
        MenuBarExtra("PodPals", systemImage: "airpodspro.chargingcase.wireless.radiowaves.left.and.right.fill") {
            AppMenu(appState: appState)
//            Button(enabled ? "Enabled" : "Disabled") {
//                                
//                enabled.toggle()    
//                    }
//                    Divider()
//                    Button("About PodPals") {
//
//
//                        }
//                    
//                    Button("Preferences") {
//
//
//                    }
//                    Divider()
//
//                        Button("Quit PodPals") {
//
//                            NSApplication.shared.terminate(nil)
//
//                        }.keyboardShortcut("q")
            
            
        }.menuBarExtraStyle(.window)
        Window("Settings", id: "settings-window") {
            ContentView(appState: appState, accessAuthorized: $appState.accessAuthorized).fixedSize().preferredColorScheme(.dark)
        }.windowResizability(.contentSize)
    }
    
}

class AppState: ObservableObject {
    /** Corrected quaternion using calibration. */
    @Published var quaternion = CMQuaternion()

    @Published var trackingEnabled = true
    
    @Published var sensitivity = "Low"
    
    @Published var leftFlick = "Previous Track"
    @Published var rightFlick = "Next Track"
    @Published var nod = "Play/Pause"
    
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
        return false
    }
    
}
