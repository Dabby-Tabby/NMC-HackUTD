//
//  NameSetupView.swift
//  NMC-HackUTD
//
//  Created by Nick Watts on 11/8/25.
//

import SwiftUI

struct NameSetupView: View {
    @EnvironmentObject var session: PhoneSessionManager
    @State private var name: String = ""
    @State private var navigateToDashboard = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                CrossHatchBackground(
                    lineColor: .white.opacity(0.02),
                    lineWidth: 0.3,
                    spacing: 30
                )
                .background(Color("BackgroundBlue"))
                .ignoresSafeArea()

                VStack(spacing: 36) {
                    Spacer()

                    VStack(spacing: 10) {
                        Text("Identify Yourself")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color("TextWhite"))

                        Text("Enter your first name and initial. Your team will see this when you connect.")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("TextWhite").opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color("BoxBlue"))
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color("RoyalBlue").opacity(0.25),
                                        Color("BabyBlue").opacity(0.15)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                CrossHatchBackground(
                                    lineColor: .white.opacity(0.03),
                                    lineWidth: 0.3,
                                    spacing: 14
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            )
                            .shadow(color: Color("RoyalBlue").opacity(0.25), radius: 10, x: 0, y: 6)
                            .frame(height: 130)
                            .padding(.horizontal, 30)

                        VStack(spacing: 14) {
                            TextField("e.g. Alex W.", text: $name)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("TextWhite"))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(16)
                                .padding(.horizontal, 30)
                                .focused($isFocused)
                                .submitLabel(.done)
                                .onSubmit {
                                    isFocused = false
                                }

                            Text("This will be your PulseLink identity.")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(Color("TextWhite").opacity(0.6))
                        }
                    }

                    Spacer()

                    Button(action: {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty else { return }
                        session.updateDisplayName(trimmedName)
                        session.startAdvertising()
                        navigateToDashboard = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text("Continue")
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

                    NavigationLink(
                        destination: DashboardView()
                            .navigationBarBackButtonHidden(true),
                        isActive: $navigateToDashboard
                    ) {
                        EmptyView()
                    }

                    Spacer()
                }
                .onTapGesture {
                    isFocused = false
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    NameSetupView()
        .environmentObject(PhoneSessionManager())
        .preferredColorScheme(.dark)
}
