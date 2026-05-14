//
//  ChatBubbleView.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/14.
//

import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .assistant {
                bubble
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble
            }
        }
    }

    private var bubble: some View {
        Text(message.content)
            .font(.body)
            .foregroundStyle(message.role == .assistant ? Color.primary : Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .textSelection(.enabled)
    }

    private var backgroundColor: Color {
        message.role == .assistant ? AppTheme.cardBackground : Color.blue
    }
}
