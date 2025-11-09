//
//  LaunchView.swift
//  NMC-HackUTD
//
//  Created by Nick Watts on 11/8/25.
//

import SwiftUI

struct LaunchView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // 🔹 Crosshatch background
                CrossHatchBackground(
                    lineColor: .white.opacity(0.02),
                    lineWidth: 0.3,
                    spacing: 30
                )
                .ignoresSafeArea(.all)
                .background(Color("BackgroundBlue"))
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // 🔹 First carousel — Technician Systems
                    FadingAutoScrollView(variant: 1)
                        .padding(.top, 30)
                    
                    // 🔹 Second carousel — Field Communication & Connectivity
                    FadingAutoScrollView(initialOffset: 140, variant: 2)
                        .padding(.bottom, 40)
                        .padding(.top, -60)
                    
                    // 🔹 Logo and Title Section
                    VStack(spacing: 16) {
                        ZStack {
                            // 🌈 Soft rainbow glow behind logo
                            LinearGradient(
                                gradient: Gradient(colors: [
                                      Color("RoyalBlue"),
                                      Color("BabyBlue"),
                                      Color("RoyalBlue")
                                  ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .overlay(
                                CrossHatchBackground(
                                    lineColor: .white.opacity(1.0),
                                    lineWidth: 0.3,
                                    spacing: 12
                                )
                                .ignoresSafeArea(.all)
                                )
                            .blur(radius: 3)
                            .frame(width: 480, height: 160)
                            .cornerRadius(40)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 5)
                            .opacity(0.8)
                            .padding(.horizontal, 40)
                            
                            // 🔹 PulseLink Logo Card
                            RoundedRectangle(cornerRadius: 35)
                                .fill(Color("BoxBlue"))
                                .frame(width: 120, height: 120)
                                .shadow(color: Color("TextWhite").opacity(0.05), radius: 8, x: 0, y: 4)
                                .shadow(color: Color("TextWhite").opacity(0.05), radius: 8, x: 0, y: -4)
                                .overlay(
                                    Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 70, height: 70)
                                        .foregroundColor(Color("TextWhite").opacity(0.9))
                                        .shadow(color: Color("RoyalBlue").opacity(0.8), radius: 10)
                                )
                        }
                        .padding(.bottom, 16)
                        
                        VStack(spacing: 6) {
                            Text("PulseLink")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(Color("TextWhite"))
                            
                            Text("Monitor team vitals, stay connected, and manage live field safety.")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("TextWhite").opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .frame(width: 350, height: 50)
                        }
                    }
                    
                    // 🔹 Get Started Button
                    NavigationLink(destination: PermissionsPage()) {
                        Text("Enter Control Center")
                            .font(.headline.bold())
                            .foregroundColor(Color("TextWhite"))
                            .padding(.horizontal, 100)
                            .padding(.vertical, 15)
                            .background(Color("RoyalBlue"))
                            .cornerRadius(26)
                            .shadow(color: Color("RoyalBlue").opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color("BackgroundBlue").ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
        }
    }
}

//
// MARK: - Fading Auto Scroll View
//
struct FadingAutoScrollView: View {
    var initialOffset: CGFloat = 0
    var variant: Int = 1
    
    var body: some View {
        ZStack {
            InfiniteAutoScrollingCarousel(initialOffset: initialOffset, variant: variant)
            
            // Left fade
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color("BackgroundBlue"), location: 0.0),
                    .init(color: Color("BackgroundBlue").opacity(0.8), location: 0.25),
                    .init(color: Color("BackgroundBlue").opacity(0.0), location: 1.0)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 120)
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right fade
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color("BackgroundBlue").opacity(0.0), location: 0.0),
                    .init(color: Color("BackgroundBlue").opacity(0.8), location: 0.75),
                    .init(color: Color("BackgroundBlue"), location: 1.0)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 120)
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

//
// MARK: - Auto Scrolling Carousel
//
struct InfiniteAutoScrollingCarousel: View {
    let items = Array(0..<4)
    @State private var scrollOffset: CGFloat
    @State private var timer: Timer?
    private let itemWidth: CGFloat = 200
    private let spacing: CGFloat = 20
    private let scrollSpeed: CGFloat = 0.3
    var variant: Int = 1
    
    init(initialOffset: CGFloat = 0, variant: Int = 1) {
        _scrollOffset = State(initialValue: initialOffset)
        self.variant = variant
    }
    
    var body: some View {
        let totalItemWidth = itemWidth + spacing
        let totalWidth = totalItemWidth * CGFloat(items.count)
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(Array((items + items).enumerated()), id: \.offset) { index, _ in
                    if variant == 1 {
                        switch index % items.count {
                        case 0: CarCard(symbol: "waveform.path.ecg", title: "Vitals Monitor", subtitle: "Heart rate, O₂, energy tracking")
                        case 1: CarCard(symbol: "antenna.radiowaves.left.and.right", title: "Signal Link", subtitle: "Multipeer connectivity status")
                        case 2: CarCard(symbol: "person.2.wave.2.fill", title: "Team Sync", subtitle: "Nearby technicians connected")
                        case 3: CarCard(symbol: "bolt.heart.fill", title: "Stress Watch", subtitle: "Detect elevated strain early")
                        default: EmptyView()
                        }
                    } else {
                        switch index % items.count {
                        case 0: CarCard(symbol: "location.circle.fill", title: "Field Map", subtitle: "Track active field locations")
                        case 1: CarCard(symbol: "bell.badge.fill", title: "Alert Log", subtitle: "Incoming ping & warning history")
                        case 2: CarCard(symbol: "network", title: "System Mesh", subtitle: "Device pairing and node graph")
                        case 3: CarCard(symbol: "lock.shield.fill", title: "Data Security", subtitle: "Encrypted transmission layer")
                        default: EmptyView()
                        }
                    }
                }
            }
            .offset(x: -scrollOffset)
            .onAppear { startAutoScroll(totalWidth: totalWidth) }
            .onDisappear { stopAutoScroll() }
        }
    }
    
    private func startAutoScroll(totalWidth: CGFloat) {
        stopAutoScroll()
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            scrollOffset += scrollSpeed
            if scrollOffset >= totalWidth { scrollOffset = 0 }
        }
    }
    
    private func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
    }
}

//
// MARK: - Car Card (PulseLink)
struct CarCard: View {
    var symbol: String
    var title: String
    var subtitle: String

    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(Color("BoxBlue"))
            .frame(width: 200, height: 130)
            .overlay(
                ZStack {
                    // 🔹 Subtle crosshatch texture
                    CrossHatchBackground(
                        lineColor: .white.opacity(0.01),
                        lineWidth: 0.8,
                        spacing: 10
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    // 🔹 Card content
                    VStack {
                        HStack {
                            Image(systemName: symbol)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color("TextWhite"))
                                .padding([.top, .leading], 12)
                                .shadow(color: Color("RoyalBlue").opacity(0.4), radius: 6)
                            Spacer()
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color("TextWhite"))
                                .padding(.leading, 6)
                            Text(subtitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color("TextWhite").opacity(0.7))
                                .padding(.leading, 6)
                        }
                        .padding([.leading, .bottom], 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            )
            .shadow(color: Color("RoyalBlue").opacity(0.15), radius: 5, x: 2, y: 4)
            .padding(.vertical)
    }
}

#Preview {
    LaunchView()
        .preferredColorScheme(.dark)
}
