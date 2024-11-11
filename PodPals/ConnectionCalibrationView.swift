import SwiftUI

enum GestureAction: String, CaseIterable {
    case playPause = "Play/Pause"
    case nextTrack = "Next Track"
    case previousTrack = "Previous Track"
    case volumeUp = "Volume Up"
    case volumeDown = "Volume Down"
    
    func execute() {
        switch self {
        case .playPause:
            SpotifyController.shared.playPause()
            MusicController.shared.playPause()
        case .nextTrack:
            SpotifyController.shared.nextTrack()
            MusicController.shared.nextTrack()
        case .previousTrack:
            SpotifyController.shared.previousTrack()
            MusicController.shared.previousTrack()
        case .volumeUp:
            SpotifyController.shared.adjustVolume(up: true)
            MusicController.shared.adjustVolume(up: true)
        case .volumeDown:
            SpotifyController.shared.adjustVolume(up: false)
            MusicController.shared.adjustVolume(up: false)
        }
    }
}

class SpotifyController {
    static let shared = SpotifyController()
    
    func playPause() {
        executeAppleScript("""
            tell application "Spotify"
                if it is running then
                    if player state is playing then
                        pause
                    else
                        play
                    end if
                end if
            end tell
            """)
    }
    
    func nextTrack() {
        executeAppleScript("""
            tell application "Spotify"
                if it is running then
                    next track
                end if
            end tell
            """)
    }
    
    func previousTrack() {
        executeAppleScript("""
            tell application "Spotify"
                if it is running then
                    previous track
                end if
            end tell
            """)
    }
    
    func adjustVolume(up: Bool) {
        let adjustment = up ? "set sound volume to (sound volume + 10)" : "set sound volume to (sound volume - 10)"
        executeAppleScript("""
            tell application "Spotify"
                if it is running then
                    \(adjustment)
                end if
            end tell
            """)
    }
    
    private func executeAppleScript(_ script: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let scriptObject = NSAppleScript(source: script) {
                var error: NSDictionary?
                scriptObject.executeAndReturnError(&error)
            }
        }
    }
}

class MusicController {
    static let shared = MusicController()
    
    func playPause() {
        executeAppleScript("""
            tell application "Music"
                if it is running then
                    if player state is playing then
                        pause
                    else
                        play
                    end if
                end if
            end tell
            """)
    }
    
    func nextTrack() {
        executeAppleScript("""
            tell application "Music"
                if it is running then
                    next track
                end if
            end tell
            """)
    }
    
    func previousTrack() {
        executeAppleScript("""
            tell application "Music"
                if it is running then
                    previous track
                end if
            end tell
            """)
    }
    
    func adjustVolume(up: Bool) {
        let adjustment = up ? "set sound volume to (sound volume + 10)" : "set sound volume to (sound volume - 10)"
        executeAppleScript("""
            tell application "Music"
                if it is running then
                    \(adjustment)
                end if
            end tell
            """)
    }
    
    private func executeAppleScript(_ script: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let scriptObject = NSAppleScript(source: script) {
                var error: NSDictionary?
                scriptObject.executeAndReturnError(&error)
            }
        }
    }
}


struct ConnectionView: View {
    @ObservedObject var appState: AppState

    @State private var yawInDegrees = 0.0
    @State private var pitchInDegrees = 0.0
    @State private var rollInDegrees = 0.0

    
    @State var previousYaw: Double = 0.0
    
    @State var previousPitch: Double = 0.0
    
    let alpha = 0.2
    
    let debounceTime: TimeInterval = 1.0

    @State var lastGestureActivationTime: TimeInterval = 0
    @State private var connected = true
    
    func recognizeFlick(yaw: Double, threshold: Double, currentTime: TimeInterval) {
            let filteredYaw = alpha * yaw + (1 - alpha) * previousYaw
            let yawChange = filteredYaw - previousYaw
            previousYaw = filteredYaw
            
            if abs(yawChange) > threshold {
                if currentTime - lastGestureActivationTime >= debounceTime {
                    if yawChange > 0 {
                        lastGestureActivationTime = currentTime
                        print("Left Flick Detected")
                        if let action = GestureAction(rawValue: appState.leftFlick) {
                            action.execute()
                        }
                    } else {
                        lastGestureActivationTime = currentTime
                        print("Right Flick Detected")
                        if let action = GestureAction(rawValue: appState.rightFlick) {
                            action.execute()
                        }
                    }
                }
            }
        }
    
    func recognizeNod(pitch: Double, threshold: Double, currentTime: TimeInterval) {
            let filteredPitch = alpha * pitch + (1 - alpha) * previousPitch
            let pitchChange = filteredPitch - previousPitch
            previousPitch = filteredPitch
            
            if abs(pitchChange) > threshold {
                if currentTime - lastGestureActivationTime >= debounceTime {
                    if pitchChange > 0 {
                        lastGestureActivationTime = currentTime
                        print("Down Nod Detected")
                        if let action = GestureAction(rawValue: appState.nod) {
                            action.execute()
                        }
                    }
                }
            }
        }
    
    var body: some View {
        VStack {
            Text(connected ? "Connected" : "Not Connected")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(connected ? Color.green : Color.red)

            HStack {
                Text("Yaw:").foregroundColor(.gray)
                Text(String(format: "%.1f°", yawInDegrees)).foregroundColor(.gray).frame(width: 50)
            }

            HStack {
                Text("Pitch:").foregroundColor(.gray)
                Text(String(format: "%.1f°", pitchInDegrees)).foregroundColor(.gray).frame(width: 50)
            }

            HStack {
                Text("Roll:").foregroundColor(.gray)
                Text(String(format: "%.1f°", rollInDegrees)).foregroundColor(.gray).frame(width: 50)
            }
        }
        .onReceive(appState.headphoneMotionDetector.$connected) {
            newState in connected = newState
        }
        .onReceive(
            appState.$quaternion.throttle(for: 0.10, scheduler: RunLoop.main, latest: true)
        ) { newRotation in
            if appState.trackingEnabled {
                let quaternion = newRotation.toAmbisonicCoordinateSystem()
                let taitBryan = quaternion.toTaitBryan()
                
                yawInDegrees = rad2deg(taitBryan.yaw)
                pitchInDegrees = rad2deg(taitBryan.pitch)
                rollInDegrees = rad2deg(taitBryan.roll)
                
                let currentTime = Date().timeIntervalSince1970
                
                var threshold = 10.0
                var nodThreshold = 4.0
                
                if appState.sensitivity == "Low" {
                    threshold = 10.0
                    nodThreshold = 4.0
                } else if appState.sensitivity == "Medium" {
                    threshold = 7.0
                    nodThreshold = 3.0
                } else {
                    threshold = 4.0
                    nodThreshold = 2.0
                }

                
                recognizeFlick(yaw: yawInDegrees, threshold: threshold, currentTime: currentTime)
                recognizeNod(pitch: pitchInDegrees, threshold: nodThreshold, currentTime: currentTime)
            }
        }
    }
    
}

struct ConnectionCalibrationView: View {
    var appState: AppState

    var body: some View {
        VStack {
            ConnectionView(appState: appState)

            Button(action: {
                appState.trackingEnabled.toggle()
                appState.headphoneMotionDetector.calibration.resetOrientation()
                appState.trackingEnabled.toggle()
            }) {
                Text("Reset Orientation")
            }

            PressedReleaseButton(buttonText: "Full Calibration", onDown: { appState.headphoneMotionDetector.calibration.start() }, onRelease: { appState.headphoneMotionDetector.calibration.finish() })
            Text("Press, nod, release to calibrate")
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
}

struct PressedReleaseButton: View {
    @GestureState private var pressed = false
    @State private var pressing = false

    let buttonText: String
    var onDown: () -> Void
    var onRelease: () -> Void

    var body: some View {
        Text(buttonText)
            .padding(4)
            .background(self.pressing ? Color.red : Color.blue)
            .cornerRadius(6)

            .gesture(DragGesture(minimumDistance: 0.0)
                .onChanged { _ in
                    if !self.pressing {
                        self.pressing = true
                        onDown()
                    }
                }
                .onEnded { _ in
                    self.pressing = false
                    onRelease()
                })
    }
}

