//
//  ContentView.swift
//  NMC-HackUTD
//
//  Created by Nick Watts on 11/8/25.
//

import SwiftUI
import WatchConnectivity
import Combine

class PhoneSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var heartRate: Double = 0
    @Published var oxygen: Double = 0
    @Published var energy: Double = 0
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.heartRate = message["heartRate"] as? Double ?? 0
            self.oxygen = message["oxygen"] as? Double ?? 0
            self.energy = message["energy"] as? Double ?? 0
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}

struct DashboardView: View {
    @StateObject private var session = PhoneSessionManager()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Technician Health Dashboard")
                .font(.title2)
                .bold()
            
            HStack {
                MetricCard(title: "Heart Rate", value: "\(Int(session.heartRate)) bpm", symbol: "heart.fill", color: .red)
                MetricCard(title: "Oxygen", value: "\(String(format: "%.0f", session.oxygen))%", symbol: "lungs.fill", color: .blue)
            }
            HStack {
                MetricCard(title: "Energy", value: "\(String(format: "%.0f", session.energy)) kcal", symbol: "flame.fill", color: .orange)
            }
            Spacer()
        }
        .padding()
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: symbol)
                .font(.largeTitle)
                .foregroundColor(color)
            Text(title).font(.headline)
            Text(value).font(.title3).bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
    }
}

#Preview {
    DashboardView()
}
