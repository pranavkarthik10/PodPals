//
//  AppMenu.swift
//  PodPals
//
//  Created by Pranav Karthik on 2023-11-26.
//

import SwiftUI

struct AppMenu: View {
    @ObservedObject var appState: AppState
    @State private var connected = true
    @Environment(\.openWindow) var openWindow
    
    var options = ["Low", "Medium", "High"]
    var gestureOptions = ["Previous Track", "Next Track", "Play/Pause", "Disabled"]
    var body: some View {
        VStack
        {
            HStack {
                Image("podpals").resizable().frame(width:40, height: 40).cornerRadius(12).padding(15)
                Text("PodPals").bold()
                Spacer()
                Button("Settings") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    openWindow(id: "settings-window")
                    
                }.padding(15)

            }
            
            HStack {
                Text(connected ? "Connected" : "Not Connected")
                    .padding(.horizontal, 15)
                Spacer()
                Image(systemName: "circle.fill").padding(.horizontal, 15).foregroundColor(connected ? .green : .red)
                
            }.padding(.top, 5)
            HStack {
                Text("Sensitivity").padding(.horizontal, 15)
                Spacer()
                Picker("", selection: $appState.sensitivity) {
                    ForEach(options, id: \.self) {
                        Text($0)
                    }
                }.padding(.horizontal, 15)
                .pickerStyle(.segmented)
            }.padding(.vertical, 15)
            
            HStack {
                Text("Left Flick").padding(.horizontal, 15)
                Spacer()
                Picker("", selection: $appState.leftFlick) {
                    ForEach(gestureOptions, id: \.self) {
                        Text($0)
                    }
                }.frame(width: 150)
                    .padding(.horizontal, 15)
                    .pickerStyle(.menu)
            }.padding(.vertical, 5)
            HStack {
                Text("Right Flick").padding(.horizontal, 15)
                Spacer()
                Picker("", selection: $appState.rightFlick) {
                    ForEach(gestureOptions, id: \.self) {
                        Text($0)
                    }
                }.frame(width: 150).padding(.horizontal, 15)
                    .pickerStyle(.menu)
            }.padding(.vertical, 5)
            HStack {
                Text("Nod").padding(.horizontal, 15)
                Spacer()
                Picker("", selection: $appState.nod) {
                    ForEach(gestureOptions, id: \.self) {
                        Text($0)
                    }
                }.frame(width: 150).padding(.horizontal, 15)
                    .pickerStyle(.menu)
            }.padding(.vertical, 5)
            
            Spacer()
            HStack {
                Spacer()
                Button("Quit") {
                    
                    NSApplication.shared.terminate(nil)
                    
                }.keyboardShortcut("q").padding(.vertical, 15)
                Button(appState.trackingEnabled ? "Pause Tracking" : "Start Tracking") {
                    appState.trackingEnabled.toggle()
                    
                }.padding(15)

            }
        }.frame(width:300, height:350)
            .onReceive(appState.headphoneMotionDetector.$connected) {
                newState in connected = newState
            }
    }
}

#Preview {
    AppMenu(appState: AppState.init())
}
