//
//  ChatBubble.swift
//  NMC-HackUTD
//
//  Created by Nick Watts on 11/9/25.
//

import SwiftUI

/// A reusable message bubble used in the BuddyView chat UI.
struct ChatBubble: View {
    let text: String
    let isUser: Bool
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundColor(.white.opacity(0.95))
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(color)
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .fixedSize(horizontal: false, vertical: true) // allow wrapping
    }
}
