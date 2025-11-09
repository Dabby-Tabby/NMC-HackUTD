// ContentView.swift (watch target)
import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @StateObject private var health = HealthDataManager()
    
    var body: some View {
        VStack(spacing: 8) {
            Text("PulseLink")
                .font(.headline)
            
            // You can show live vitals if you want:
            Text("HR: \(Int(health.heartRate)) bpm")
            Text("O₂: \(Int(health.oxygen))%")
            Text("Energy: \(Int(health.energy)) kcal")
        }
        .padding()
    }
}
