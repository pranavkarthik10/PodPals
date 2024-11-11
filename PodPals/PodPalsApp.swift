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
    
    init () {
        UserDefaults.registerDefaults()
    }
    
    var body: some Scene {
        MenuBarExtra("PodPals", systemImage: "airpodspro.chargingcase.wireless.radiowaves.left.and.right.fill") {
            AppMenu(appState: appState)
            
            
        }.menuBarExtraStyle(.window)
        Window("Calibrate", id: "settings-window") {
            ContentView(appState: appState, accessAuthorized: $appState.accessAuthorized).fixedSize().preferredColorScheme(.dark)
        }.windowResizability(.contentSize)
    }
    
}

class AppState: ObservableObject {
    /** Corrected quaternion using calibration */
    @Published var quaternion = CMQuaternion()
    
    @Published var trackingEnabled = true {
        willSet {
            UserDefaults.standard.set(newValue, forKey: "trackingEnabled")
        }
    }
    
    @Published var sensitivity: String {
        willSet {
            UserDefaults.standard.set(newValue, forKey: "sensitivity")
        }
    }
    
    @Published var leftFlick: String {
        willSet {
            UserDefaults.standard.set(newValue, forKey: "leftFlick")
        }
    }
    
    @Published var rightFlick: String {
        willSet {
            UserDefaults.standard.set(newValue, forKey: "rightFlick")
        }
    }
    
    @Published var nod: String {
        willSet {
            UserDefaults.standard.set(newValue, forKey: "nod")
        }
    }
    
    @AppStorage("AppState.calibration") private var calibration: Data = .init()
    
    private var accessCheckTimer = Timer()
    @Published var accessAuthorized = HeadphoneMotionDetector.isAuthorized()
    
    var headphoneMotionDetector = HeadphoneMotionDetector()
    
    init() {
        // Initialize with stored values or defaults
        self.sensitivity = UserDefaults.standard.string(forKey: "sensitivity") ?? "Low"
        self.leftFlick = UserDefaults.standard.string(forKey: "leftFlick") ?? "Previous Track"
        self.rightFlick = UserDefaults.standard.string(forKey: "rightFlick") ?? "Next Track"
        self.nod = UserDefaults.standard.string(forKey: "nod") ?? "Play/Pause"
        self.trackingEnabled = UserDefaults.standard.bool(forKey: "trackingEnabled")
        
        // Set up motion detector
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

extension UserDefaults {
    enum Keys {
        static let sensitivity = "sensitivity"
        static let leftFlick = "leftFlick"
        static let rightFlick = "rightFlick"
        static let nod = "nod"
        static let trackingEnabled = "trackingEnabled"
    }
    
    static let defaults: [String: Any] = [
        Keys.sensitivity: "Medium",
        Keys.leftFlick: "Previous Track",
        Keys.rightFlick: "Next Track",
        Keys.nod: "Play/Pause",
        Keys.trackingEnabled: true
    ]
    
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: defaults)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {}

    func applicationWillTerminate(_: Notification) {
        UserDefaults.standard.synchronize()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return false
    }
    
}
