//
//  PermissionsPage.swift
//  NMC-HackUTD
//
//  Created by Nick Watts on 11/8/25.
//

import SwiftUI
import HealthKit
import AVFoundation

struct PermissionsPage: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var onboarding: OnboardingCoordinator
    
    @State private var showingHealthPrompt = false
    @State private var showingMicPrompt = false
    @State private var navigateToNameSetup = false
    private let healthStore = HKHealthStore()

    var body: some View {
        NavigationStack {
            ZStack {
                // 🔹 Background: PulseLink blue + crosshatch
                CrossHatchBackground(
                    lineColor: .white.opacity(0.02),
                    lineWidth: 0.3,
                    spacing: 30
                )
                .background(Color("BackgroundBlue"))
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // 🔹 Header
                    VStack(spacing: 10) {
                        Text("System Permissions")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color("TextWhite"))

                        Text("PulseLink requires limited access to monitor your health data and enable real-time communication.")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("TextWhite").opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    // 🔹 Permission Cards
                    VStack(spacing: 22) {
                        PermissionCardView(
                            icon: "waveform.path.ecg",
                            title: "Health Access",
                            description: "Allows PulseLink to read heart rate, oxygen, and motion data for live monitoring.",
                            gradientColors: [Color("RoyalBlue"), Color("BabyBlue")]
                        )

                        PermissionCardView(
                            icon: "mic.fill",
                            title: "Microphone Access",
                            description: "Used for live voice transmission and team alerts in the field.",
                            gradientColors: [Color("RoyalBlue"), Color("BabyBlue")]
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    Spacer()

                    // 🔹 Allow Access Button
                    Button(action: requestPermissions) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text("Allow Access")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(Color("TextWhite"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color("RoyalBlue"))
                        .cornerRadius(30)
                        .shadow(color: Color("RoyalBlue").opacity(0.5), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 30)
                    }

                    // 🔹 Hidden Navigation Trigger → NameSetupView
//                    NavigationLink(
//                        destination: NameSetupView()
//                            .navigationBarBackButtonHidden(true),
//                        isActive: $navigateToNameSetup
//                    ) {
//                        EmptyView()
//                    }

                    Spacer()
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - Request Health & Microphone Permissions
    private func requestPermissions() {
        requestHealthAccess()
        requestMicrophoneAccess()
    }
    
    private func finishPermissions() {
        onboarding.step = .nameSetup
    }

    private func requestHealthAccess() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let readTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ HealthKit permission granted.")
                    self.showingHealthPrompt = true
                    checkCompletion()
                } else {
                    print("❌ HealthKit permission denied: \(error?.localizedDescription ?? "Unknown")")
                }
            }
        }
    }

    private func requestMicrophoneAccess() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Microphone permission granted.")
                    self.showingMicPrompt = true
                    checkCompletion()
                } else {
                    print("❌ Microphone permission denied.")
                }
            }
        }
    }

    private func checkCompletion() {
        if showingHealthPrompt && showingMicPrompt {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                navigateToNameSetup = true
                finishPermissions()
            }
        }
    }
}

//
// MARK: - Permission Card View
//
struct PermissionCardView: View {
    var icon: String
    var title: String
    var description: String
    var gradientColors: [Color]

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color("BoxBlue"))
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            gradientColors[0].opacity(0.25),
                            gradientColors[1].opacity(0.15)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                )
                .shadow(color: gradientColors[0].opacity(0.25), radius: 10, x: 0, y: 6)
                .overlay(
                    CrossHatchBackground(
                        lineColor: .white.opacity(0.03),
                        lineWidth: 0.3,
                        spacing: 14
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                )

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: gradientColors[0].opacity(0.4), radius: 8, x: 0, y: 4)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("TextWhite"))

                    Text(description)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color("TextWhite").opacity(0.7))
                        .lineLimit(3)
                }

                Spacer()
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
    }
}

#Preview {
    PermissionsPage()
        .preferredColorScheme(.dark)
}
