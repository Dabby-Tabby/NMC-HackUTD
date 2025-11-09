//
//  ContentView.swift
//  Watch-NMC-HackUTD Watch App
//
//  Created by Nick Watts on 11/8/25.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @StateObject private var health = FakeHealthDataManager()
    @State private var selectedPulse: String? = nil
    
    let pulses = [
        ("Alex", "person.fill"),
        ("Help", "exclamationmark.triangle"),
        ("Part", "shippingbox"),
        ("Hot", "flame")
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            Text("PulseLink")
                .font(.headline)
            
            // Fake "live" health metrics
            VStack(spacing: 2) {
                Text("❤️ \(Int(health.heartRate)) bpm")
                Text("🩸 \(Int(health.oxygen))% O₂")
                Text("🔥 \(Int(health.energy)) kcal")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 6)
            
            ForEach(pulses, id: \.0) { (name, icon) in
                Button {
                    withAnimation {
                        selectedPulse = name
                        WKInterfaceDevice.current().play(.success)
                        // Also push the current fake data immediately on tap
                        // (in addition to the 5s timer)
                        health.sendToPhone()
                    }
                } label: {
                    HStack {
                        Image(systemName: icon)
                        Text(name)
                        Spacer()
                        if selectedPulse == name {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedPulse == name ?
                                  Color.green.opacity(0.2) :
                                  Color.gray.opacity(0.2))
                    )
                }
            }
            
            Spacer()
            
            Button("Emergency SOS") {
                WKInterfaceDevice.current().play(.failure)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
