//
//  GroqAPIKeyView.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/14.
//

import SwiftUI

struct GroqAPIKeyView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var apiKey: String
    @State private var draftKey: String

    init(apiKey: Binding<String>) {
        _apiKey = apiKey
        _draftKey = State(initialValue: apiKey.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Groq API Key") {
                    SecureField("gsk_...", text: $draftKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Text("This is a prototype-friendly setup. For a production app, move Groq calls behind your own backend so the key is never stored in the app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Groq Setup")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: close)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: save)
                }
            })
        }
        .presentationDetents([.medium])
    }

    private func close() {
        dismiss()
    }

    private func save() {
        apiKey = draftKey.trimmingCharacters(in: .whitespacesAndNewlines)
        dismiss()
    }
}
