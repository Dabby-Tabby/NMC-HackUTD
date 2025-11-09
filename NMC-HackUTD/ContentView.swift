//
//  ContentView.swift
//  NMC-HackUTD
//
//  Created by Nick Watts on 11/8/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedPeer: String? = nil
    @State private var messageSent: Bool = false
    
    let peers = ["Alex", "Jordan", "Sam", "Taylor"]
    let pulseTypes = [
        ("✅ OK", "checkmark.circle.fill"),
        ("🆘 Help", "exclamationmark.triangle.fill"),
        ("📦 Need Part", "shippingbox.fill"),
        ("🔥 Hot Zone", "flame.fill")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack {
                    Text("PulseLink")
                        .font(.largeTitle).bold()
                    Text("Silent Communication for Noisy Environments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)
                
                // Nearby Peers
                VStack(alignment: .leading) {
                    Text("Nearby Technicians")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(peers, id: \.self) { peer in
                                Button {
                                    selectedPeer = peer
                                } label: {
                                    VStack {
                                        Circle()
                                            .fill(selectedPeer == peer ? Color.green : Color.blue)
                                            .frame(width: 60, height: 60)
                                            .overlay(Text(String(peer.prefix(1)))
                                                .font(.title).bold()
                                                .foregroundColor(.white))
                                        Text(peer)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider().padding(.horizontal)
                
                // Pulse Buttons
                VStack(alignment: .leading, spacing: 10) {
                    Text("Send Pulse")
                        .font(.headline)
                    
                    ForEach(pulseTypes, id: \.0) { (name, icon) in
                        Button {
                            messageSent.toggle()
                        } label: {
                            HStack {
                                Image(systemName: icon)
                                    .foregroundColor(.blue)
                                Text(name)
                                    .fontWeight(.medium)
                                Spacer()
                                if messageSent {
                                    Image(systemName: "waveform.path.ecg")
                                        .foregroundColor(.green)
                                        .transition(.opacity)
                                }
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6)))
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(.green)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
