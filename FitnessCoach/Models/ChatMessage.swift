//
//  ChatMessage.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/14.
//

import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatMessageRole
    let content: String
    let createdAt = Date()
}
