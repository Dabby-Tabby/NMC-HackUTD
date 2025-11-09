//
//  ContentView.swift
//  Watch-NMC-HackUTD Watch App
//
//  Created by Nick Watts on 11/8/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedPulse: String? = nil
    
    let pulses = [
        ("OK", "checkmark.circle"),
        ("Help", "exclamationmark.triangle"),
        ("Part", "shippingbox"),
        ("Hot", "flame")
    ]
    
    var body: some View {
        VStack(spacing: 10) {
            Text("PulseLink")
                .font(.headline)
                .padding(.bottom, 5)
            
            ForEach(pulses, id: \.0) { (name, icon) in
                Button {
                    withAnimation {
                        selectedPulse = name
                        WKInterfaceDevice.current().play(.success)
                    }
                } label: {
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(.blue)
                        Text(name)
                            .fontWeight(.medium)
                        Spacer()
                        if selectedPulse == name {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8)
                        .fill(selectedPulse == name ? Color.green.opacity(0.2) : Color.gray.opacity(0.2)))
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
