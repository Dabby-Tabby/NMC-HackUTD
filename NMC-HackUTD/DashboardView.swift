//
//  ContentView.swift
//  NMC-HackUTD
//
//  Created by Nick Watts on 11/8/25.
//

import SwiftUI
import Neumorphic

// MARK: - Global UI Constants
private let textOpacity: Double = 0.8

// MARK: - Employee Model
struct Employee: Identifiable {
    let id = UUID()
    let name: String
    let heartRate: Double
    let oxygen: Double
    let energy: Double
}

// MARK: - Dashboard
struct DashboardView: View {
    @StateObject private var session = PhoneSessionManager()
    
    @State private var employees = [
        Employee(name: "Alex W.",   heartRate: 88, oxygen: 97, energy: 130),
        Employee(name: "Jordan P.", heartRate: 76, oxygen: 95, energy: 120),
        Employee(name: "Sam K.",    heartRate: 91, oxygen: 98, energy: 145),
        Employee(name: "Taylor R.", heartRate: 83, oxygen: 96, energy: 110),
        Employee(name: "Riley M.",  heartRate: 79, oxygen: 99, energy: 155)
    ]
    
    var body: some View {
        ZStack {
            Color("BackgroundBlue").ignoresSafeArea()
            CrossHatchBackground(
                lineColor: .white.opacity(0.02),
                lineWidth: 0.3,
                spacing: 30
            )
            .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Technician Health Dashboard")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("TextWhite").opacity(textOpacity))
                        .padding(.top, 10)
                    
                    VStack(spacing: 20) {
                        ForEach(employees) { emp in
                            EmployeeCard(employee: emp) {
                                print("ALERT sent to \(emp.name)")
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.error)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            
            if let from = session.lastPingFrom {
                VStack {
                    HStack {
                        Image(systemName: "bolt.horizontal.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("TextWhite").opacity(textOpacity))
                        VStack(alignment: .leading) {
                            Text("Ping Received")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("TextWhite").opacity(textOpacity))
                            Text("You've been pinged by \(from)")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(Color("TextWhite").opacity(textOpacity * 0.9))
                        }
                        Spacer()
                        Button(action: { session.lastPingFrom = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color("TextWhite").opacity(textOpacity))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("BoxBlue"))
                    )
                    .padding(.horizontal)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: session.lastPingFrom)
            }
        }
    }
}

struct EmployeeCard: View {
    let employee: Employee
    let onPing: () -> Void
    @State private var isAlerting = false
    
    var body: some View {
        ZStack {
            // MARK: - Background Layers
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("BoxBlue"))
                .overlay(
                    CrossHatchBackground(
                        lineColor: .white.opacity(0.01),
                        lineWidth: 0.8,
                        spacing: 10
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color("TextWhite").opacity(0.05), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                .frame(height: 180)
            
            // MARK: - Card Content
            VStack(alignment: .leading, spacing: 14) {
                // Technician name
                Text(employee.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextWhite").opacity(textOpacity))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider().background(Color("TextWhite").opacity(0.15))
                
                // Main row: health metrics + alert button
                HStack(alignment: .center) {
                    // Left side — metrics
                    VStack(alignment: .leading, spacing: 14) {
                        MetricRow(icon: {
                            HeartBeatIcon(
                                bpm: employee.heartRate,
                                color: Color("DowngradeRed"),
                                size: 24,
                                glow: true
                            )
                        }, label: "\(Int(employee.heartRate)) bpm", color: Color("TextWhite"))
                        
                        MetricRow(icon: {
                            LungsBreathIcon(
                                brpm: 12,
                                color: Color("BabyBlue"),
                                size: 24,
                                glow: true,
                                airflow: true
                            )
                        }, label: "\(Int(employee.oxygen))%", color: Color("TextWhite"))

                        
                        MetricRow(icon: {
                            Image(systemName: "flame.fill")
                                .foregroundColor(Color("IncreaseGreen"))
                                .frame(width: 24, height: 24)
                        }, label: "\(Int(employee.energy)) kcal", color: Color("TextWhite"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Right side — centered alert button
                    VStack {
                        Spacer()
                        AlertButton(isAlerting: $isAlerting, onPing: onPing)
                            .frame(width: 130, height: 65)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Subviews

struct MetricRow<Icon: View>: View {
    var icon: () -> Icon
    var label: String
    var color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            icon()
                .frame(width: 28, height: 20)
            Text(label)
                .foregroundColor(color.opacity(0.8))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
    }
}

struct AlertButton: View {
    @Binding var isAlerting: Bool
    var onPing: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) { isAlerting = true }
            onPing()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.3)) { isAlerting = false }
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("DowngradeRed"))
                    .overlay(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color("DowngradeRed").opacity(isAlerting ? 0.9 : 0.5),
                                .clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: isAlerting ? 100 : 60
                        )
                        .blur(radius: 12)
                    )
                    .shadow(color: Color("DowngradeRed").opacity(isAlerting ? 0.7 : 0.4),
                            radius: isAlerting ? 18 : 10)
                    .scaleEffect(isAlerting ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.25), value: isAlerting)
                
                Text("ALERT")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextWhite").opacity(0.9))
                    .shadow(color: Color("DowngradeRed").opacity(0.8), radius: 8)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
