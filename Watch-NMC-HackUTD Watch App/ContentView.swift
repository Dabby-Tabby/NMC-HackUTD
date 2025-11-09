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
            // 🔹 Crosshatch background (consistent visual)
            CrossHatchBackground(
                lineColor: .white.opacity(0.15),
                lineWidth: 0.4,
                spacing: 20
            )
            .ignoresSafeArea()
            .background(Color("BoxBlue").ignoresSafeArea())
            
            // 🔹 Swipeable pages
            TabView {
                // View 1: All vitals together
                VStack(spacing: 12) {
                    
                    HeartBeatIcon(
                        bpm: health.heartRate,
                        color: .red,
                        size: 30,
                        glow: true
                    )
                    Text("\(Int(health.heartRate)) bpm")
                        .font(.system(size: 16, weight: .medium))
                    
                    LungsBreathIcon(
                        brpm: 12,
                        color: Color("BabyBlue"),
                        size: 30,
                        glow: true,
                        airflow: true
                    )
                    Text("\(Int(health.oxygen))% O₂")
                        .font(.system(size: 16, weight: .medium))
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color("IncreaseGreen"))
                    Text("\(Int(health.energy)) kcal")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding()
                
                // View 2: Heart Rate
                VStack(spacing: 8) {
                    HeartBeatIcon(
                        bpm: health.heartRate,
                        color: .red,
                        size: 100,
                        glow: true
                    )
                    Text("\(Int(health.heartRate)) bpm")
                        .font(.title3)
                        .bold()
                }
                .foregroundColor(.white)
                
                // View 3: Oxygen
                VStack(spacing: 8) {
                    LungsBreathIcon(
                        brpm: 12,
                        color: Color("BabyBlue"),
                        size: 100,
                        glow: true,
                        airflow: true
                    )
                    Text("\(Int(health.oxygen))% O₂")
                        .font(.title3)
                        .bold()
                }
                .foregroundColor(.white)
                
                // View 4: Energy
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 100))
                        .foregroundColor(Color("IncreaseGreen"))
                    Text("\(Int(health.energy)) kcal")
                        .font(.title3)
                        .bold()
                }
                .foregroundColor(.white)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            
            // ✅ Ping banner overlay
            if health.showPingBanner {
                PingBanner()
            }
        }
        .animation(.spring(), value: health.showPingBanner)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
