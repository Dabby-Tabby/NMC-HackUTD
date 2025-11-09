//
//  ContentView.swift
//  iPad-NMC-HackUTD
//
//  Created by Nick Watts on 11/9/25.
//

import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    @StateObject private var session = PhoneSessionManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color("BackgroundBlue").ignoresSafeArea()
                CrossHatchBackground(
                    lineColor: .white.opacity(0.02),
                    lineWidth: 0.3,
                    spacing: 30
                )
                .ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        Label("PulseLink", systemImage: "waveform.path.ecg.rectangle")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color("TextWhite").opacity(0.85))
                            .padding(.top, 30)
                            .shadow(color: Color("TextWhite").opacity(0.3), radius: 3)
                        
                        // Connection Status
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                                .foregroundColor(session.connectedPeers.isEmpty ? .gray : Color("BabyBlue"))
                                .font(.system(size: 22))
                            Text(session.connectedPeers.isEmpty ?
                                 "Waiting for connections..." :
                                 "Connected to \(session.connectedPeers.count) peers")
                                .foregroundColor(Color("TextWhite").opacity(0.7))
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Active Employees List
                        if session.connectedPeers.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 50))
                                    .foregroundColor(Color("TextWhite").opacity(0.4))
                                Text("No team members online")
                                    .foregroundColor(Color("TextWhite").opacity(0.6))
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                            }
                            .padding(.top, 60)
                        } else {
                            VStack(spacing: 20) {
                                ForEach(session.connectedPeers, id: \.self) { peer in
                                    let vitals = session.peerVitals[peer.displayName]
                                    EmployeeCard(
                                        employee: Employee(
                                            name: peer.displayName,
                                            heartRate: vitals?.heart,
                                            oxygen: vitals?.oxygen,
                                            energy: vitals?.energy
                                        ),
                                        onPing: {} // iPad doesn't send pings
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
        }
        .onAppear {
            session.myDisplayName = "iPad Dashboard"
            session.startAdvertising()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MockSessionManager().base)
        .preferredColorScheme(.dark)
}
