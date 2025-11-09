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
        NavigationStack {
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
                        Label("Vitals Command Center", systemImage: "waveform.path.ecg.rectangle")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("TextWhite").opacity(textOpacity))
                            .padding(.top, 10)
                            .shadow(color: Color("TextWhite").opacity(0.4), radius: 3)
                        
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
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: DashboardView()) {
                            Image(systemName: "heart.text.clipboard.fill")
                        }
                        .padding(.leading, 12)

                        Divider()
                            .frame(height: 20)
                            .background(Color.white.opacity(0.3))

                        NavigationLink(destination: WorkOrderListView()) {
                            Image(systemName: "list.clipboard.fill")
                        }

                        Divider()
                            .frame(height: 20)
                            .background(Color.white.opacity(0.3))

                        NavigationLink(destination: BuddyView()) {
                            Image(systemName: "cpu.fill")
                        }
                        .padding(.trailing, 12)
                    }
                }
            }
            .toolbarBackground(Color("BoxBlue"), for: .bottomBar)
            .toolbarBackground(.visible, for: .bottomBar)
        }
    }
}


// MARK: - Employee Card
struct EmployeeCard: View {
    let employee: Employee
    let onPing: () -> Void
    @State private var isAlerting = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
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
                    WaveOverlay()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color("TextWhite").opacity(0.05), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                .frame(height: 180)
            
            VStack(alignment: .leading, spacing: 14) {
                Text(employee.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextWhite").opacity(textOpacity))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .shadow(color: Color("TextWhite").opacity(0.4), radius: 3)
                
                Divider()
                    .background(Color("TextWhite").opacity(0.15))
                    .shadow(color: Color("TextWhite"), radius: 2)
                
                HStack(alignment: .center) {
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
                    
                    VStack {
                        Spacer()
                        AlertButton(isAlerting: $isAlerting, onPing: onPing)
                            .frame(width: 80, height: 80)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Circle()
                .fill(Color("IncreaseGreen"))
                .frame(width: 10, height: 10)
                .shadow(color: Color("IncreaseGreen").opacity(0.8), radius: 10, x: 0, y: 0)
                .shadow(color: Color("TextWhite").opacity(0.2), radius: 3, x: 0, y: 0)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
                .padding(15)
                .opacity(0.95)
                .scaleEffect(1.0 + 0.05 * sin(Date().timeIntervalSinceReferenceDate * 3))
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: UUID())
        }
    }
}

// MARK: - Metric Row
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

// MARK: - Alert Button
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
                Circle()
                    .fill(Color("PingYellow"))
                    .frame(width: 80, height: 80)
                    .overlay(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color("PingYellow").opacity(isAlerting ? 0.5 : 0.1),
                                .clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: isAlerting ? 120 : 60
                        )
                        .blur(radius: 15)
                    )
                    .shadow(
                        color: Color("PingYellow").opacity(isAlerting ? 0.5 : 0.2),
                        radius: isAlerting ? 20 : 10
                    )
                    .scaleEffect(isAlerting ? 1.15 : 1.0)
                
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color("TextWhite").opacity(0.9))
                    .shadow(color: Color("PingYellow").opacity(0.6), radius: 6)
                    .scaleEffect(isAlerting ? 1.2 : 1.0)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wave Overlay
struct WaveOverlay: View {
    var color1: Color = Color("TextWhite")
    var color2: Color = Color("RoyalBlue")
    var amplitude: CGFloat = 8
    var frequency: CGFloat = 1.5
    var speed: CGFloat = 0.6
    var opacity: Double = 0.1
    
    @State private var phase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let _ = phaseUpdater(date: timeline.date)
            
            ZStack {
                WaveShape(amplitude: amplitude, frequency: frequency, phase: phase)
                    .stroke(color1.opacity(opacity), lineWidth: 2)
                    .shadow(color: color1.opacity(0.2), radius: 4)
                
                WaveShape(amplitude: amplitude * 1.3, frequency: frequency * 0.8, phase: phase + .pi)
                    .stroke(color2.opacity(opacity), lineWidth: 2)
                    .shadow(color: color2.opacity(0.2), radius: 4)
            }
        }
        .drawingGroup()
    }
    
    private func phaseUpdater(date: Date) -> Bool {
        phase = CGFloat(date.timeIntervalSinceReferenceDate * speed)
        return true
    }
}

// MARK: - Wave Shape
struct WaveShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let width = rect.width
        let step = width / 80
        
        path.move(to: CGPoint(x: 0, y: midY))
        for x in stride(from: 0, through: width, by: step) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * frequency * 2 + phase)
            let y = midY + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
