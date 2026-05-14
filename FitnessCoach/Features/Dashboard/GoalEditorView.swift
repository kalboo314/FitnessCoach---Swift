//
//  GoalEditorView.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/7.
//

import SwiftUI

struct GoalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var dailyGoal: Double
    @State private var draftGoal: Double

    init(dailyGoal: Binding<Double>) {
        _dailyGoal = dailyGoal
        _draftGoal = State(initialValue: dailyGoal.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Calorie Goal") {
                    TextField(
                        "Calories",
                        value: $draftGoal,
                        format: .number.precision(.fractionLength(0))
                    )
                    .keyboardType(.numberPad)

                    LabeledContent("Target") {
                        Text("\(draftGoal.formatted(.number.precision(.fractionLength(0)))) kcal")
                            .bold()
                    }

                    Slider(value: $draftGoal, in: 200...1600, step: 25)
                }

                Section("How to use it") {
                    Text("Choose a goal that feels challenging but realistic for your current training week.")
                    Text("The dashboard compares Apple Health Active Energy against this target and adapts your workout suggestions.")
                }
            }
            .navigationTitle("Edit Goal")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: close)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: save)
                }
            })
        }
        .presentationDetents([.medium, .large])
    }

    private func close() {
        dismiss()
    }

    private func save() {
        dailyGoal = draftGoal
        dismiss()
    }
}
