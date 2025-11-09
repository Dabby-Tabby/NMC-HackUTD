//
//  NomiAssistantView.swift
//  NMC-HackUTD
//
//  Created by Nick Watts on 11/8/25.
//

import SwiftUI
import Neumorphic

struct NomiAssistantView: View {
    // MARK: - Environment & State
    @EnvironmentObject var session: PhoneSessionManager
    @StateObject private var workOrderViewModel = WorkOrderViewModel()
    @StateObject private var viewModel: NomiAssistantViewModel
    @Namespace private var bottomID
    @State private var userInput = ""

    private let textOpacity: Double = 0.85

    // MARK: - Custom Init (personalized greeting)
    init(session: PhoneSessionManager) {
        _workOrderViewModel = StateObject(wrappedValue: WorkOrderViewModel())
        _viewModel = StateObject(
            wrappedValue: NomiAssistantViewModel(
                userName: session.myDisplayName,
                workOrderViewModel: WorkOrderViewModel()
            )
        )
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                mainContent
            }
            .navigationBarBackButtonHidden(true)
            .hideKeyboardOnTap()
        }
    }
}

// MARK: - Subviews
extension NomiAssistantView {

    // MARK: Background
    private var backgroundView: some View {
        ZStack {
            Color("BackgroundBlue").ignoresSafeArea()
            CrossHatchBackground(
                lineColor: .white.opacity(0.02),
                lineWidth: 0.3,
                spacing: 30
            )
            .ignoresSafeArea()
        }
    }

    // MARK: Main Content
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 20) {
            headerSection
            chatLog
            inputArea
        }
        .padding(.bottom, 20)
    }

    // MARK: Header
    private var headerSection: some View {
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
    }

    // MARK: Chat Log
    @ViewBuilder
    private var chatLog: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(viewModel.messages) { msg in
                        chatMessageBubble(for: msg)
                    }

                    if viewModel.isLoading {
                        loadingIndicator
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
    }

    // MARK: Input Area
    private var inputArea: some View {
        HStack(spacing: 10) {
            HStack {
                Image(systemName: "brain.head.profile.fill")
                    .foregroundColor(.white.opacity(0.7))
                
                TextField("Type a command or question...", text: $userInput, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .foregroundColor(.white.opacity(2))
                    .lineLimit(1...3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .glassEffect()

            // Mic Button
            Button {
                viewModel.toggleListening()
            } label: {
                Image(systemName: viewModel.isListening ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(viewModel.isListening ? .red : .accentColor)
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
            }

            // Send Button
            Button {
                sendPrompt()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }

    // MARK: Chat Bubble + Play Button
    @ViewBuilder
    private func chatMessageBubble(for msg: ChatMessage) -> some View {
        VStack(alignment: msg.sender == .user ? .trailing : .leading, spacing: 4) {
            ChatBubble(
                text: msg.text.isEmpty ? "Listening..." : msg.text,
                isUser: msg.sender == .user,
                color: msg.sender == .user
                    ? (msg.id == viewModel.liveMessageID ? Color.accentColor.opacity(0.6) : Color.accentColor)
                    : Color("BoxBlue")
            )
            .animation(.easeInOut(duration: 0.1), value: msg.text)

            if msg.sender == .nomi {
                Button {
                    viewModel.speak(msg.text)
                } label: {
                    Label("Play", systemImage: "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.leading, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: msg.sender == .user ? .trailing : .leading)
        .padding(msg.sender == .user ? .trailing : .leading, 16)
        .padding(.vertical, 2)
    }

    // MARK: Loading Indicator
    private var loadingIndicator: some View {
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

    // MARK: Helpers
    private func sendPrompt() {
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.sendMessage(trimmed)
        userInput = ""
    }
}

#Preview {
    NomiAssistantView(session: PhoneSessionManager())
        .environmentObject(PhoneSessionManager())
        .preferredColorScheme(.dark)
}

// MARK: - Dismiss Keyboard Helper
extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }
}
