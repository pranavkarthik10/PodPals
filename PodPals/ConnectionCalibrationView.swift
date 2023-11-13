import SwiftUI

struct ConnectionView: View {
    var appState: AppState

    @State private var yawInDegrees = 0.0
    @State private var pitchInDegrees = 0.0
    @State private var rollInDegrees = 0.0

    
    let threshold: Double = 10.0
    let nodThreshold: Double = 4.0
    @State var previousYaw: Double = 0.0
    
    @State var previousPitch: Double = 0.0
    
    let alpha = 0.2
    
    let debounceTime: TimeInterval = 1.0

    @State var lastGestureActivationTime: TimeInterval = 0
    
    func recognizeFlick(yaw: Double, threshold: Double, currentTime: TimeInterval) {
        let filteredYaw = alpha * yaw + (1 - alpha) * previousYaw
        let yawChange = filteredYaw - previousYaw
        previousYaw = filteredYaw
        
        if abs(yawChange) > threshold {
            // Check if enough time has passed since the last activation
            if currentTime - lastGestureActivationTime >= debounceTime {
                if yawChange > 0 {
                    lastGestureActivationTime = currentTime
                    print("Left Flick Detected")
                    prevTrackSpotify()
                } else {
                    lastGestureActivationTime = currentTime
                    print("Right Flick Detected")
                    nextTrackSpotify()
                }
            }
        }
        
    }
    
    func recognizeNod(pitch: Double, threshold: Double, currentTime: TimeInterval) {
        let filteredPitch = alpha * pitch + (1 - alpha) * previousPitch
        let pitchChange = filteredPitch - previousPitch
        previousPitch = filteredPitch
        
        if abs(pitchChange) > threshold {
            // Check if enough time has passed since the last activation
            if currentTime - lastGestureActivationTime >= debounceTime {
                if pitchChange > 0 {
                    lastGestureActivationTime = currentTime
                    print("Down Nod Detected")
                    playPauseSpotify()
                } else {
                    lastGestureActivationTime = currentTime
                    print("Up Nod Detected")
                }
            }
        }
        
    }
    
    func playPauseSpotify() {
        DispatchQueue.global(qos: .userInitiated).async {
            let script = """
        tell application "Spotify"
            if it is running then
                if player state is playing then
                    pause
                else
                    play
                end if
            end if
        end tell
        """
            if let scriptObject = NSAppleScript(source: script) {
                var error: NSDictionary?
                scriptObject.executeAndReturnError(&error)
            }
        }
    }

    // Function to skip to the next track in Spotify
    func nextTrackSpotify() {
        DispatchQueue.global(qos: .userInitiated).async {
            let script = """
        tell application "Spotify"
            next track
        end tell
        """
            if let scriptObject = NSAppleScript(source: script) {
                var error: NSDictionary?
                scriptObject.executeAndReturnError(&error)
            }
        }
    }

    func prevTrackSpotify() {
        DispatchQueue.global(qos: .userInitiated).async {
            let script = """
        tell application "Spotify"
            previous track
        end tell
        """
            if let scriptObject = NSAppleScript(source: script) {
                var error: NSDictionary?
                scriptObject.executeAndReturnError(&error)
            }
        }
    }
    
    @State private var connected = true
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
            let quaternion = newRotation.toAmbisonicCoordinateSystem()
            let taitBryan = quaternion.toTaitBryan()

            yawInDegrees = rad2deg(taitBryan.yaw)
            pitchInDegrees = rad2deg(taitBryan.pitch)
            rollInDegrees = rad2deg(taitBryan.roll)
            
            let currentTime = Date().timeIntervalSince1970
            
            recognizeFlick(yaw: yawInDegrees, threshold: threshold, currentTime: currentTime)
            recognizeNod(pitch: pitchInDegrees, threshold: nodThreshold, currentTime: currentTime)
        }
    }
    
}

struct ConnectionCalibrationView: View {
    var appState: AppState

    var body: some View {
        VStack {
            ConnectionView(appState: appState)

            Button(action: {
                appState.headphoneMotionDetector.calibration.resetOrientation()
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
