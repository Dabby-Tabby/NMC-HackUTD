//
//  ContentView.swift
//  iPad-NMC-HackUTD
//
//  Created by Nick Watts on 11/9/25.
//

import SwiftUI
import MultipeerConnectivity

private enum Keys {
    static let displayName = "PulseLinkDisplayName"
}

struct ContentView: View {
    @StateObject private var session = PhoneSessionManager()
    @StateObject private var onboarding = OnboardingCoordinator()
    @State private var showPeerOrdersFor: MCPeerID? = nil
    
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
                                    
                                    // Make the entire card tappable to open work orders
                                    Button {
                                        session.requestWorkOrders(from: peer)
                                        showPeerOrdersFor = peer
                                    } label: {
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
                                    .buttonStyle(.plain) // preserve card styling without button chrome
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                        }
                    }
                }
                
                // Onboarding overlays
                switch onboarding.step {
                case .launch:
                    LaunchView()
                        .environmentObject(onboarding)
                        .transition(.opacity)
                        .zIndex(1)
                        .onChange(of: onboarding.step) { _, new in
                            if new == .permissions {
                                onboarding.step = .nameSetup
                            }
                        }
                case .permissions:
                    Color.clear.onAppear {
                        onboarding.step = .nameSetup
                    }
                    .zIndex(1)
                case .nameSetup:
                    NameSetupView()
                        .environmentObject(session)
                        .environmentObject(onboarding)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                        .onChange(of: onboarding.step) { _, new in
                            if new == .completed {
                                let name = session.myDisplayName
                                UserDefaults.standard.set(name, forKey: Keys.displayName)
                                if name.isEmpty == false {
                                    session.startAdvertising()
                                }
                            }
                        }
                case .completed:
                    EmptyView()
                }
            }
            .navigationDestination(item: $showPeerOrdersFor) { peer in
                PeerWorkOrdersView(peerName: peer.displayName)
                    .environmentObject(session)
            }
        }
        .onAppear {
            if let saved = UserDefaults.standard.string(forKey: Keys.displayName),
               saved.isEmpty == false {
                session.updateDisplayName(saved)
                onboarding.step = .completed
            } else {
                session.myDisplayName = "iPad Dashboard"
                onboarding.step = .launch
            }
            if onboarding.step == .completed {
                session.startAdvertising()
            }
        }
    }
}

#Preview("Card opens work orders") {
// Seed a saved display name so onboarding completes immediately

UserDefaults.standard.set("Preview User", forKey: "PulseLinkDisplayName")


return ContentView()

    .environmentObject(MockSessionManager().base)

    .preferredColorScheme(.dark)

    .previewLayout(.fixed(width: 1024, height: 768))

}
