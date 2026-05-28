//
//  UserProfileView.swift
//  FitnessCoach
//

import SwiftUI

struct UserProfileView: View {
    @StateObject private var model = UserProfileModel()
    @AppStorage("dailyCalorieGoal") private var dailyCalorieGoal: Double = 650

    @State private var heightText = ""
    @State private var weightText = ""
    @State private var useMetric = true
    @State private var showSaved = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.largeSpacing) {
                measurementsCard

                if model.isProfileComplete {
                    bmiCard
                    goalCard
                    calorieCard
                }

                themeCard
            }
            .padding(AppTheme.screenPadding)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("My Profile")
        .onAppear { syncInputsFromModel() }
        .onChange(of: useMetric) { _ in syncInputsFromModel() }
        .overlay(alignment: .top) {
            if showSaved {
                Text("Profile saved")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.green.clipShape(Capsule()))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSaved)
    }

    // MARK: - Measurements

    private var measurementsCard: some View {
        profileCard {
            Label("Body Measurements", systemImage: "person.fill")
                .font(.headline).bold()

            unitToggle

            inputField(
                title: useMetric ? "Height (cm)" : "Height",
                hint: useMetric ? "e.g. 170" : "e.g. 5'10 or 70",
                text: $heightText
            )

            inputField(
                title: useMetric ? "Weight (kg)" : "Weight (lbs)",
                hint: useMetric ? "e.g. 70" : "e.g. 154",
                text: $weightText
            )

            if model.isProfileComplete {
                Text(useMetric
                    ? "≈ \(model.profile.heightFeetInches) · \(String(format: "%.1f", model.profile.weightLbs)) lbs"
                    : "≈ \(Int(model.heightCm)) cm · \(String(format: "%.1f", model.weightKg)) kg"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Button(action: saveMeasurements) {
                Label("Save Measurements", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(heightText.isEmpty || weightText.isEmpty)
        }
    }

    // MARK: - BMI

    private var bmiCard: some View {
        let p = model.profile
        return profileCard {
            Label("BMI", systemImage: "waveform.path.ecg").font(.headline).bold()

            HStack(alignment: .bottom, spacing: 14) {
                Text(String(format: "%.1f", p.bmi))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(p.bmiCategory.color)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: p.bmiCategory.systemImage)
                        Text(p.bmiCategory.label).bold()
                    }
                    .font(.subheadline)
                    .foregroundStyle(p.bmiCategory.color)

                    Text("Healthy: 18.5 – 24.9")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            bmiScaleBar(bmi: p.bmi)

            Text(p.bmiCategory.recommendation)
                .font(.body)
                .foregroundStyle(.secondary)

            if p.bmiCategory.suggestedGoal != model.goal {
                Button(action: { withAnimation { model.goal = p.bmiCategory.suggestedGoal } }) {
                    Label(
                        "Switch to recommended: \(p.bmiCategory.suggestedGoal.displayName)",
                        systemImage: "wand.and.stars"
                    )
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(p.bmiCategory.color)
            }
        }
    }

    @ViewBuilder
    private func bmiScaleBar(bmi: Double) -> some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    LinearGradient(
                        colors: [.blue, .green, .green, .orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 10)
                    .clipShape(Capsule())

                    let fraction = (min(max(bmi, 15), 40) - 15) / 25
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                        .shadow(radius: 3)
                        .offset(x: geo.size.width * fraction - 9, y: -4)
                }
            }
            .frame(height: 18)

            HStack {
                ForEach(["15", "18.5", "25", "30", "40"], id: \.self) { val in
                    Text(val).font(.caption2).foregroundStyle(.secondary)
                    if val != "40" { Spacer() }
                }
            }
        }
    }

    // MARK: - Goal Picker

    private var goalCard: some View {
        profileCard {
            Label("Fitness Goal", systemImage: "target").font(.headline).bold()

            Text("Choose what you want to focus on. Your calorie and workout targets will adjust automatically.")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                    goalRow(goal)
                }
            }
        }
    }

    private func goalRow(_ goal: FitnessGoal) -> some View {
        let selected = model.goal == goal
        return Button(action: { withAnimation { model.goal = goal } }) {
            HStack(spacing: 14) {
                Image(systemName: goal.icon)
                    .font(.title3)
                    .foregroundStyle(goal.color)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.displayName).font(.body).bold()
                    Text(goal.detail).font(.caption).foregroundStyle(.secondary)
                }

                Spacer()

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(goal.color)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(14)
            .background(selected ? goal.color.opacity(0.10) : Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(selected ? goal.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Calorie Calculator

    private var calorieCard: some View {
        let p = model.profile
        return profileCard {
            HStack {
                Label("Calorie & Macro Target", systemImage: "fork.knife.circle.fill")
                    .font(.headline).bold()
                Spacer()
                Button(action: applyToDashboard) {
                    Label("Apply to Dashboard", systemImage: "arrow.up.forward.circle")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.small)
            }

            VStack(spacing: 2) {
                Text("\(Int(p.targetCalories))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                Text("kcal / day")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Maintenance estimate: \(Int(p.maintenanceCalories)) kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)

            Divider()

            VStack(spacing: 12) {
                macroRow("Protein", grams: p.proteinGrams, cal: p.proteinGrams * 4, color: .red, total: p.targetCalories)
                macroRow("Carbs", grams: p.carbGrams, cal: p.carbGrams * 4, color: .orange, total: p.targetCalories)
                macroRow("Fat", grams: p.fatGrams, cal: p.fatGrams * 9, color: .yellow, total: p.targetCalories)
            }

            foodGuide(goal: model.goal)

            Text("These are estimates based on your weight and goal. Adjust gradually based on real-world results.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func macroRow(_ name: String, grams: Double, cal: Double, color: Color, total: Double) -> some View {
        let fraction = total > 0 ? min(cal / total, 1.0) : 0
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(name).font(.subheadline).bold()
                Spacer()
                Text("\(Int(grams))g · \(Int(cal)) kcal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.18)).frame(height: 8)
                    Capsule().fill(color).frame(width: geo.size.width * fraction, height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    @ViewBuilder
    private func foodGuide(goal: FitnessGoal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Daily Food Guide", systemImage: "list.bullet").font(.subheadline).bold()

            let tips = foodTips(for: goal)
            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                    Text(tip)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func foodTips(for goal: FitnessGoal) -> [String] {
        switch goal {
        case .increaseMass:
            return [
                "Split your calories across 4–5 meals to support muscle protein synthesis.",
                "Prioritise protein at every meal — eggs, chicken, fish, legumes, or dairy.",
                "Include complex carbs (rice, oats, sweet potato) before and after training.",
                "Add healthy fats (nuts, avocado, olive oil) to hit your surplus comfortably.",
                "Eat a protein-rich snack before bed to support overnight recovery."
            ]
        case .decreaseWeight:
            return [
                "Eat 3 meals with a small protein-rich snack to control hunger.",
                "Fill half your plate with vegetables to stay full on fewer calories.",
                "Lean proteins (chicken, fish, tofu) should anchor every meal.",
                "Limit liquid calories — juice, soda, and alcohol add up fast.",
                "Save your largest meal for post-workout to improve recovery and satiety."
            ]
        case .maintain:
            return [
                "Eat balanced meals across 3–4 sittings spread through the day.",
                "Aim for a fist of protein, a fist of carbs, and plenty of veg at each meal.",
                "Stay hydrated — aim for at least 2 litres of water daily.",
                "Enjoy treats in moderation without guilt; consistency beats perfection.",
                "Track your weight weekly (same day, same time) to confirm you are on track."
            ]
        }
    }

    // MARK: - Theme

    private var themeCard: some View {
        profileCard {
            Label("Appearance", systemImage: "paintpalette.fill").font(.headline).bold()

            Picker("Theme", selection: $model.colorSchemeRaw) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)

            Text("Changes take effect immediately across the app.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Reusable helpers

    @ViewBuilder
    private func profileCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }

    private var unitToggle: some View {
        HStack(spacing: 0) {
            Button(action: { useMetric = true }) {
                Text("Metric")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(useMetric ? Color.blue : Color.clear)
                    .foregroundStyle(useMetric ? Color.white : Color.primary)
            }
            Button(action: { useMetric = false }) {
                Text("Imperial")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(!useMetric ? Color.blue : Color.clear)
                    .foregroundStyle(!useMetric ? Color.white : Color.primary)
            }
        }
        .background(Color(UIColor.tertiarySystemFill))
        .clipShape(Capsule())
    }

    private func inputField(title: String, hint: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            TextField(hint, text: text)
                .keyboardType(.decimalPad)
                .padding(12)
                .background(Color(UIColor.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Logic

    private func syncInputsFromModel() {
        if useMetric {
            heightText = model.heightCm > 0 ? String(format: "%.0f", model.heightCm) : ""
            weightText = model.weightKg > 0 ? String(format: "%.1f", model.weightKg) : ""
        } else {
            if model.heightCm > 0 {
                let totalInches = model.heightCm / 2.54
                let feet = Int(totalInches / 12)
                let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
                heightText = "\(feet)'\(inches)"
            } else {
                heightText = ""
            }
            weightText = model.weightKg > 0 ? String(format: "%.1f", model.weightKg * 2.20462) : ""
        }
    }

    private func saveMeasurements() {
        if useMetric {
            if let h = Double(heightText), h > 0 { model.heightCm = h }
            if let w = Double(weightText), w > 0 { model.weightKg = w }
        } else {
            if let cm = parseImperialHeight(heightText) { model.heightCm = cm }
            if let lbs = Double(weightText), lbs > 0 { model.weightKg = lbs / 2.20462 }
        }
        applyToDashboard()
        withAnimation {
            showSaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaved = false }
        }
    }

    private func parseImperialHeight(_ text: String) -> Double? {
        let parts = text.split(separator: "'")
        if parts.count == 2, let feet = Double(parts[0]), let inches = Double(parts[1]) {
            return (feet * 12 + inches) * 2.54
        }
        if let totalInches = Double(text), totalInches > 0 {
            return totalInches * 2.54
        }
        return nil
    }

    private func applyToDashboard() {
        guard model.isProfileComplete else { return }
        dailyCalorieGoal = model.profile.targetCalories
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            UserProfileView()
        }
    }
}
