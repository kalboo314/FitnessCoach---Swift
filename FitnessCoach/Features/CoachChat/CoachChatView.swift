//
//  CoachChatView.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/14.
//

import SwiftUI

struct CoachChatView: View {
    @AppStorage("groqApiKey") private var groqApiKey = ""
    @ObservedObject var model: CoachChatModel
    let snapshot: FitnessSnapshot
    @State private var isShowingAPIKeySheet = false

    private let quickPrompts = [
        "How can I hit my calorie goal today?",
        "Give me a short workout based on my progress.",
        "What should I eat after training?",
        "How should I recover tonight?"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.largeSpacing) {
                CoachContextCardView(snapshot: snapshot)

                if groqApiKey.isEmpty {
                    HealthStatusCardView(
                        state: .unknown,
                        message: "Add your Groq API key to start chatting with the coach. For a production app, move this behind your own backend instead of storing it on-device.",
                        actionTitle: "Add Groq Key",
                        action: openAPIKeySheet
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Prompts")
                        .font(.headline)
                        .bold()

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(quickPrompts, id: \.self) { prompt in
                                Button(action: {
                                    fillPrompt(prompt)
                                }) {
                                    Text(prompt)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.leading)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Color.white.opacity(0.85))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding(AppTheme.cardPadding)
                        .background(Color.white.opacity(0.88))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }

                VStack(spacing: 12) {
                    ForEach(model.messages) { message in
                        ChatBubbleView(message: message)
                    }

                    if model.isSending {
                        ProgressView("Coach is thinking...")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(AppTheme.screenPadding)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Coach Chat")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Groq Key", action: openAPIKeySheet)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset", action: resetConversation)
            }
        })
        .safeAreaInset(edge: .bottom) {
            HStack(alignment: .bottom, spacing: 12) {
                TextField(
                    "Ask for tips, workouts, meals, or recovery guidance",
                    text: $model.composerText,
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(sendButtonColor)
                }
                .disabled(sendButtonDisabled)
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $isShowingAPIKeySheet) {
            GroqAPIKeyView(apiKey: $groqApiKey)
        }
    }

    private var sendButtonDisabled: Bool {
        model.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isSending || groqApiKey.isEmpty
    }

    private var sendButtonColor: Color {
        sendButtonDisabled ? Color.gray : Color.blue
    }

    private func openAPIKeySheet() {
        isShowingAPIKeySheet = true
    }

    private func fillPrompt(_ prompt: String) {
        model.fillComposer(with: prompt)
    }

    private func resetConversation() {
        model.resetConversation()
    }

    private func sendMessage() {
        Task {
            await model.sendMessage(apiKey: groqApiKey, snapshot: snapshot)
        }
    }
}

struct CoachChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CoachChatView(
                model: CoachChatModel(),
                snapshot: FitnessSnapshot(date: .now, activeEnergyBurned: 320, dailyGoal: 650)
            )
        }
    }
}
