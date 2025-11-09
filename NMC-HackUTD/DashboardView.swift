//
//  ContentView.swift
//  NMC-HackUTD
//
//  Created by Nick Watts on 11/8/25.
//
import SwiftUI

struct DashboardView: View {
    @StateObject private var session = PhoneSessionManager()
    
    var body: some View {
        ZStack {
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
            
            // In-app ping banner overlay
            if let from = session.lastPingFrom {
                VStack {
                    HStack {
                        Image(systemName: "bolt.horizontal.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        VStack(alignment: .leading) {
                            Text("Ping Received")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("You've been pinged by \(from)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        Spacer()
                        Button(action: {
                            // dismiss immediately
                            session.lastPingFrom = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor))
                    .shadow(radius: 6)
                    .padding(.horizontal)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: session.lastPingFrom)
            }
        }
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
            Text(title)
                .font(.headline)
            Text(value)
                .font(.title3)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}


#Preview {
    DashboardView()
}
