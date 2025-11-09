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
        Employee(name: "Alex", heartRate: 88, oxygen: 97, energy: 130),
        Employee(name: "Jordan", heartRate: 76, oxygen: 95, energy: 120),
        Employee(name: "Sam", heartRate: 91, oxygen: 98, energy: 145),
        Employee(name: "Taylor", heartRate: 83, oxygen: 96, energy: 110),
        Employee(name: "Riley", heartRate: 79, oxygen: 99, energy: 155)
    ]
    
    var body: some View {
        ZStack {
            Color("CharcoalGray").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Technician Health Dashboard")
                        .font(.title2.bold())
                        .foregroundColor(.white.opacity(textOpacity))
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
                            .foregroundColor(.white.opacity(textOpacity))
                        VStack(alignment: .leading) {
                            Text("Ping Received")
                                .font(.headline)
                                .foregroundColor(.white.opacity(textOpacity))
                            Text("You've been pinged by \(from)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(textOpacity * 0.9))
                        }
                        Spacer()
                        Button(action: { session.lastPingFrom = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(textOpacity))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("CharcoalGray"))
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

// MARK: - Employee Card
struct EmployeeCard: View {
    let employee: Employee
    let onPing: () -> Void
    @State private var isAlerting = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CharcoalGray"))
                .frame(height: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 16) {
                Text(employee.name)
                    .font(.title3.bold())
                    .foregroundColor(.white.opacity(textOpacity))
                
                Divider().background(Color.white.opacity(0.15))
                
                HStack(alignment: .center, spacing: 16) {
                    // Left: Health data
                    VStack(alignment: .leading, spacing: 14) {
                        // ❤️ Heart Rate
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color("CharcoalGray"))
                                    .frame(width: 28, height: 28)
                                    .background(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                .red.opacity(0.7),
                                                .clear
                                            ]),
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 25
                                        )
                                        .blur(radius: 10)
                                    )
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                            }
                            Text("\(Int(employee.heartRate)) bpm")
                                .foregroundColor(.white.opacity(textOpacity))
                        }
                        
                        // 💨 Oxygen
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color("CharcoalGray"))
                                    .frame(width: 28, height: 28)
                                    .background(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                .blue.opacity(0.7),
                                                .clear
                                            ]),
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 25
                                        )
                                        .blur(radius: 10)
                                    )
                                Image(systemName: "lungs.fill")
                                    .foregroundColor(.blue)
                            }
                            Text("\(Int(employee.oxygen))%")
                                .foregroundColor(.white.opacity(textOpacity))
                        }
                        
                        // 🔥 Energy
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color("CharcoalGray"))
                                    .frame(width: 28, height: 28)
                                    .background(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                .orange.opacity(0.7),
                                                .clear
                                            ]),
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 25
                                        )
                                        .blur(radius: 10)
                                    )
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                            }
                            Text("\(Int(employee.energy)) kcal")
                                .foregroundColor(.white.opacity(textOpacity))
                        }
                    }
                    .font(.subheadline.bold())
                    
                    Spacer()
                    
                    // Right: Animated ALERT button with glowing effect
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isAlerting = true
                        }
                        onPing()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isAlerting = false
                            }
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.red)
                                .frame(width: 150, height: 80)
                                .overlay(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            .red.opacity(isAlerting ? 0.9 : 0.5),
                                            .clear
                                        ]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: isAlerting ? 100 : 60
                                    )
                                    .blur(radius: 12)
                                )
                                .scaleEffect(isAlerting ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.25), value: isAlerting)
                            
                            Text("ALERT")
                                .font(.headline.bold())
                                .foregroundColor(.white.opacity(textOpacity))
                                .shadow(color: .red.opacity(0.8), radius: 8)
                        }
                        .padding(.trailing, 30)
                        .padding(.bottom, 5)
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
