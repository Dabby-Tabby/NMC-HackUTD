//
//  BuddyView.swift
//  NMC-HackUTD
//
//  Created by Nick Watts on 11/8/25.
//

import SwiftUI
import Neumorphic

struct BuddyView: View {
    @StateObject private var viewModel = BuddyViewModel()
    @Namespace private var bottomID
    private let textOpacity: Double = 0.85

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color("BackgroundBlue").ignoresSafeArea()
                CrossHatchBackground(lineColor: .white.opacity(0.02), lineWidth: 0.3, spacing: 30)
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    // MARK: - Header
                    VStack(spacing: 6) {
                        Label("Nomi AI Assistant", systemImage: "cpu.fill")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("TextWhite").opacity(textOpacity))
                            .shadow(color: Color("TextWhite").opacity(0.3), radius: 3)

                        Text("Silent communication for NMC² data center operations.")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(Color("TextWhite").opacity(0.6))
                    }
                    .padding(.top, 10)

                    // MARK: - Live Transcript Box
                    if viewModel.isListening {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Technician Input")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("TextWhite").opacity(0.8))

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
                                .frame(height: 90)
                                .overlay(
                                    ScrollView {
                                        Text(viewModel.transcript.isEmpty
                                             ? "Listening..."
                                             : viewModel.transcript)
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundColor(Color("TextWhite").opacity(0.9))
                                            .padding(14)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                )
                        }
                        .padding(.horizontal)
                    }

                    // MARK: - Chat Log
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(viewModel.messages) { msg in
                                    ChatBubble(
                                        text: msg.text,
                                        isUser: msg.sender == .user,
                                        color: msg.sender == .user ? Color.accentColor : Color("BoxBlue")
                                    )
                                    .frame(maxWidth: .infinity, alignment: msg.sender == .user ? .trailing : .leading)
                                    .padding(msg.sender == .user ? .trailing : .leading, 16)
                                    .padding(.vertical, 2)
                                    .transition(.opacity.combined(with: .move(edge: msg.sender == .user ? .trailing : .leading)))
                                }

                                if viewModel.isLoading {
                                    HStack(spacing: 10) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        Text("Nomi is thinking...")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.white.opacity(0.7))
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }

                                Color.clear.frame(height: 10).id(bottomID)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(bottomID, anchor: .bottom)
                            }
                        }
                    }

                    // MARK: - Controls
                    HStack(spacing: 16) {
                        Button {
                            viewModel.toggleListening()
                        } label: {
                            Label(viewModel.isListening ? "Stop & Send" : "Start Listening",
                                  systemImage: viewModel.isListening ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(viewModel.isListening ? Color.red : Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
                        }

                        if viewModel.isSpeaking {
                            Button {
                                viewModel.stopSpeaking()
                            } label: {
                                Label("Stop", systemImage: "speaker.slash.circle.fill")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red.opacity(0.8))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            // MARK: - Toolbar
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: DashboardView()) {
                            Image(systemName: "heart.text.clipboard.fill")
                        }
                        .padding(.leading, 12)

                        Divider().frame(height: 20).background(Color.white.opacity(0.3))

                        NavigationLink(destination: WorkOrderListView()) {
                            Image(systemName: "list.clipboard.fill")
                        }

                        Divider().frame(height: 20).background(Color.white.opacity(0.3))

                        NavigationLink(destination: BuddyView()) {
                            Image(systemName: "cpu.fill").foregroundColor(.green)
                        }
                        .padding(.trailing, 12)
                    }
                }
            }
            .toolbarBackground(Color("BoxBlue"), for: .bottomBar)
            .toolbarBackground(.visible, for: .bottomBar)
        }
        .navigationBarBackButtonHidden(true)
    }
}
