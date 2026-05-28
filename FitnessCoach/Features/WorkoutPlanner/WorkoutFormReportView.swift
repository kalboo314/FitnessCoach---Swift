//
//  WorkoutFormReportView.swift
//  FitnessCoach
//

import SwiftUI

struct WorkoutFormReportView: View {
    let records: [RepFormRecord]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.largeSpacing) {
                    overallScoreCard
                    if !exerciseNames.isEmpty {
                        exerciseBreakdown
                    }
                }
                .padding(AppTheme.screenPadding)
                .padding(.bottom, 24)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Form Report")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Overall score card

    private var overallScoreCard: some View {
        let goodCount = records.filter { $0.category == .goodForm }.count
        let total = records.count
        let pct = total > 0 ? Double(goodCount) / Double(total) : 0.0

        return VStack(spacing: 20) {
            Text("Overall Form Score")
                .font(.headline)

            ZStack {
                Circle()
                    .stroke(Color(UIColor.tertiarySystemFill), lineWidth: 14)
                    .frame(width: 130, height: 130)
                Circle()
                    .trim(from: 0, to: pct)
                    .stroke(
                        scoreColor(pct),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: pct)
                VStack(spacing: 2) {
                    Text("\(Int(pct * 100))%")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor(pct))
                    Text("good form")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Show a pill for each category that appears in the session
            let categoryCounts = Dictionary(grouping: records, by: \.category).mapValues(\.count)
            let pillOrder: [FormFeedbackCategory] = [.goodForm, .rangeIncomplete, .kneeAlignment, .bodyNotVisible, .lowConfidence]
            let presentPills = pillOrder.filter { categoryCounts[$0] != nil }

            HStack(spacing: 0) {
                ForEach(Array(presentPills.enumerated()), id: \.element) { idx, cat in
                    if idx > 0 { Divider().frame(height: 40) }
                    scorePill(
                        icon: cat.systemImage,
                        value: "\(categoryCounts[cat] ?? 0)",
                        label: shortLabel(cat),
                        color: cat.color
                    )
                }
            }
            .padding(.vertical, 6)
            .background(Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(motivationMessage(pct: pct))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }

    // MARK: - Per-exercise breakdown

    private var exerciseBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Per Exercise", systemImage: "list.bullet.clipboard.fill")
                .font(.headline).bold()

            ForEach(exerciseNames, id: \.self) { name in
                let reps = records.filter { $0.exerciseName == name }
                    .sorted { $0.repNumber < $1.repNumber }
                exerciseCard(name: name, reps: reps)
            }
        }
    }

    private func exerciseCard(name: String, reps: [RepFormRecord]) -> some View {
        let goodCount = reps.filter { $0.category == .goodForm }.count
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text("\(goodCount)/\(reps.count) good")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Rep colour bars
            HStack(spacing: 4) {
                ForEach(reps) { rep in
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(rep.category.color)
                            .frame(height: 32)
                        Text("\(rep.repNumber)")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Category legend (only show categories that appear)
            HStack(spacing: 12) {
                ForEach(presentCategories(in: reps), id: \.self) { cat in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(cat.color)
                            .frame(width: 8, height: 8)
                        Text(cat.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(AppTheme.cardPadding)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 8, y: 4)
    }

    // MARK: - Helpers

    private var exerciseNames: [String] {
        var seen = Set<String>()
        return records.compactMap { seen.insert($0.exerciseName).inserted ? $0.exerciseName : nil }
    }

    private func presentCategories(in reps: [RepFormRecord]) -> [FormFeedbackCategory] {
        let order: [FormFeedbackCategory] = [.goodForm, .rangeIncomplete, .bodyNotVisible]
        let present = Set(reps.map(\.category))
        return order.filter { present.contains($0) }
    }

    private func shortLabel(_ cat: FormFeedbackCategory) -> String {
        switch cat {
        case .goodForm:        return "Good"
        case .rangeIncomplete: return "Shallow"
        case .kneeAlignment:   return "Knees"
        case .bodyNotVisible:  return "No Pose"
        case .lowConfidence:   return "Unclear"
        }
    }

    private func scoreColor(_ pct: Double) -> Color {
        if pct >= 0.8 { return .green }
        if pct >= 0.5 { return .orange }
        return .red
    }

    private func motivationMessage(pct: Double) -> String {
        if pct >= 0.9 { return "Excellent technique! Your form was consistently solid." }
        if pct >= 0.7 { return "Good work. Focus on hitting full depth on the reps marked incomplete." }
        if pct >= 0.5 { return "Keep practising — aim to hit depth thresholds on more reps each session." }
        return "Work on your range of motion. Slow down and focus on controlled reps."
    }

    private func scorePill(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color).font(.title3)
            Text(value).font(.headline.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
