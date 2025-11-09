//
//  ContentView.swift
//  Watch-NMC-HackUTD Watch App
//
//  Created by Nick Watts on 11/8/25.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @StateObject private var health = HealthDataManager()
    
    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                Text("PulseLink")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                // Live vitals
                Text("❤️ HR: \(Int(health.heartRate)) bpm")
                Text("🫁 O₂: \(Int(health.oxygen))%")
                Text("🔥 Energy: \(Int(health.energy)) kcal")
            }
            .padding()
            
            // ✅ Ping banner overlay (appears + fades automatically)
            if health.showPingBanner {
                PingBanner()
            }
        }
        .animation(.spring(), value: health.showPingBanner)
    }
}

#Preview {
    ContentView()
}
