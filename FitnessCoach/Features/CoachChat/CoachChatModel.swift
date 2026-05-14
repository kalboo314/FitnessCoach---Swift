//
//  CoachChatModel.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/14.
//

import Combine
import Foundation

@MainActor
final class CoachChatModel: ObservableObject {
    @Published var messages: [ChatMessage]
    @Published var composerText = ""
    @Published var isSending = false
    @Published var errorMessage: String?

    private let groqChatService: GroqChatService

    init(groqChatService: GroqChatService = GroqChatService()) {
        self.groqChatService = groqChatService
        messages = [
            ChatMessage(
                role: .assistant,
                content: "Ask me for workout tips, recovery ideas, meal suggestions, or help closing the gap to today’s calorie goal."
            )
        ]
    }

    func sendMessage(apiKey: String, snapshot: FitnessSnapshot) async {
        let trimmedMessage = composerText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedMessage.isEmpty else {
            return
        }

        guard !isSending else {
            return
        }

        let outgoingMessage = ChatMessage(role: .user, content: trimmedMessage)
        messages.append(outgoingMessage)
        composerText = ""
        errorMessage = nil
        isSending = true

        defer {
            isSending = false
        }

        do {
            let reply = try await groqChatService.reply(
                to: messages,
                apiKey: apiKey,
                snapshot: snapshot
            )

            messages.append(ChatMessage(role: .assistant, content: reply))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetConversation() {
        messages = [
            ChatMessage(
                role: .assistant,
                content: "Chat reset. Ask for a fresh workout idea, nutrition tip, or recovery plan."
            )
        ]
        composerText = ""
        errorMessage = nil
    }

    func fillComposer(with prompt: String) {
        composerText = prompt
    }
}
