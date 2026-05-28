//
//  MuscleBodyMapView.swift
//  FitnessCoach
//
//  Interactive front/back body diagram. Tap a muscle group to filter exercises.
//

import SwiftUI

// MARK: - Data

private struct MuscleZone: Identifiable {
    let id = UUID()
    let key: String          // matches LocalExerciseDatabase muscle filter key
    let displayName: String
    let rect: CGRect
    let cornerRadius: CGFloat
    let color: Color
}

// MARK: - View

struct MuscleBodyMapView: View {
    @Binding var selectedMuscle: String
    @State private var showFront = true

    private let W: CGFloat = 180
    private let H: CGFloat = 390

    var body: some View {
        VStack(spacing: 10) {
            controlsRow
            bodyCanvas
                .animation(.easeInOut(duration: 0.2), value: showFront)
                .animation(.spring(response: 0.2), value: selectedMuscle)
        }
    }

    // MARK: - Controls row

    private var controlsRow: some View {
        HStack(spacing: 10) {
            // Front / Back toggle
            HStack(spacing: 0) {
                sideButton("Front", active: showFront)  { showFront = true }
                sideButton("Back",  active: !showFront) { showFront = false }
            }
            .background(Color(UIColor.tertiarySystemFill))
            .clipShape(Capsule())

            Spacer()

            if selectedMuscle != "all" {
                Button { withAnimation { selectedMuscle = "all" } } label: {
                    HStack(spacing: 4) {
                        Text(label(for: selectedMuscle))
                            .font(.caption.weight(.semibold))
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                    }
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.purple.opacity(0.12))
                    .clipShape(Capsule())
                }
            } else {
                Text("Tap a muscle to filter")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func sideButton(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button { withAnimation { action() } } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(active ? Color.purple : Color.clear)
                .foregroundStyle(active ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Body canvas

    private var bodyCanvas: some View {
        ZStack(alignment: .topLeading) {
            BodySilhouetteView()
                .frame(width: W, height: H)

            ForEach(activeZones) { zone in
                zoneView(zone)
            }
        }
        .frame(width: W, height: H)
    }

    private func zoneView(_ zone: MuscleZone) -> some View {
        let selected = selectedMuscle == zone.key
        let anySelected = selectedMuscle == "all"

        return ZStack {
            RoundedRectangle(cornerRadius: zone.cornerRadius)
                .fill(zone.color)
                .opacity(anySelected ? 0.55 : (selected ? 0.88 : 0.15))

            if anySelected || selected {
                Text(zone.displayName)
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 2)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(width: zone.rect.width, height: zone.rect.height)
        .position(x: zone.rect.midX, y: zone.rect.midY)
        .onTapGesture {
            withAnimation(.spring(response: 0.2)) {
                selectedMuscle = selectedMuscle == zone.key ? "all" : zone.key
            }
        }
    }

    // MARK: - Helpers

    private var activeZones: [MuscleZone] { showFront ? frontZones : backZones }

    private func label(for key: String) -> String {
        let map: [String: String] = [
            "chest": "Chest", "abdominals": "Abs", "shoulders": "Shoulders",
            "biceps": "Biceps", "triceps": "Triceps", "forearms": "Forearms",
            "quadriceps": "Quads", "hamstrings": "Hamstrings", "calves": "Calves",
            "back": "Back", "lower_back": "Lower Back", "traps": "Traps",
            "glutes": "Glutes", "middle_back": "Mid Back"
        ]
        return map[key] ?? key.replacingOccurrences(of: "_", with: " ").capitalized
    }

    // MARK: - Zone definitions (180 × 390 canvas)

    private var frontZones: [MuscleZone] {[
        // Torso
        MuscleZone(key:"chest",      displayName:"Chest",    rect:CGRect(x:40,  y:62,  width:100, height:56), cornerRadius:6, color:.red),
        MuscleZone(key:"abdominals", displayName:"Abs",      rect:CGRect(x:44,  y:116, width:92,  height:86), cornerRadius:6, color:.orange),
        // Shoulders
        MuscleZone(key:"shoulders",  displayName:"Shoulder", rect:CGRect(x:6,   y:62,  width:38,  height:40), cornerRadius:6, color:.blue),
        MuscleZone(key:"shoulders",  displayName:"Shoulder", rect:CGRect(x:136, y:62,  width:38,  height:40), cornerRadius:6, color:.blue),
        // Arms
        MuscleZone(key:"biceps",     displayName:"Biceps",   rect:CGRect(x:6,   y:100, width:30,  height:58), cornerRadius:5, color:.green),
        MuscleZone(key:"biceps",     displayName:"Biceps",   rect:CGRect(x:144, y:100, width:30,  height:58), cornerRadius:5, color:.green),
        MuscleZone(key:"forearms",   displayName:"Forearm",  rect:CGRect(x:8,   y:154, width:26,  height:74), cornerRadius:5, color:.teal),
        MuscleZone(key:"forearms",   displayName:"Forearm",  rect:CGRect(x:146, y:154, width:26,  height:74), cornerRadius:5, color:.teal),
        // Legs
        MuscleZone(key:"quadriceps", displayName:"Quads",    rect:CGRect(x:38,  y:204, width:42,  height:94), cornerRadius:6, color:.purple),
        MuscleZone(key:"quadriceps", displayName:"Quads",    rect:CGRect(x:100, y:204, width:42,  height:94), cornerRadius:6, color:.purple),
        MuscleZone(key:"calves",     displayName:"Calves",   rect:CGRect(x:40,  y:296, width:36,  height:86), cornerRadius:5, color:.indigo),
        MuscleZone(key:"calves",     displayName:"Calves",   rect:CGRect(x:104, y:296, width:36,  height:86), cornerRadius:5, color:.indigo),
    ]}

    private var backZones: [MuscleZone] {[
        // Upper back
        MuscleZone(key:"traps",      displayName:"Traps",      rect:CGRect(x:40,  y:60,  width:100, height:40), cornerRadius:6, color:.orange),
        MuscleZone(key:"back",       displayName:"Lats",       rect:CGRect(x:36,  y:98,  width:50,  height:72), cornerRadius:6, color:.blue),
        MuscleZone(key:"back",       displayName:"Lats",       rect:CGRect(x:94,  y:98,  width:50,  height:72), cornerRadius:6, color:.blue),
        MuscleZone(key:"lower_back", displayName:"Lower Back", rect:CGRect(x:52,  y:168, width:76,  height:34), cornerRadius:5, color:.red),
        // Arms
        MuscleZone(key:"triceps",    displayName:"Triceps",    rect:CGRect(x:6,   y:100, width:30,  height:58), cornerRadius:5, color:.green),
        MuscleZone(key:"triceps",    displayName:"Triceps",    rect:CGRect(x:144, y:100, width:30,  height:58), cornerRadius:5, color:.green),
        // Legs
        MuscleZone(key:"glutes",     displayName:"Glutes",     rect:CGRect(x:38,  y:204, width:42,  height:48), cornerRadius:6, color:.pink),
        MuscleZone(key:"glutes",     displayName:"Glutes",     rect:CGRect(x:100, y:204, width:42,  height:48), cornerRadius:6, color:.pink),
        MuscleZone(key:"hamstrings", displayName:"Hamstrings", rect:CGRect(x:38,  y:250, width:42,  height:50), cornerRadius:5, color:.purple),
        MuscleZone(key:"hamstrings", displayName:"Hamstrings", rect:CGRect(x:100, y:250, width:42,  height:50), cornerRadius:5, color:.purple),
        MuscleZone(key:"calves",     displayName:"Calves",     rect:CGRect(x:40,  y:296, width:36,  height:86), cornerRadius:5, color:.indigo),
        MuscleZone(key:"calves",     displayName:"Calves",     rect:CGRect(x:104, y:296, width:36,  height:86), cornerRadius:5, color:.indigo),
    ]}
}

// MARK: - Body Silhouette

private struct BodySilhouetteView: View {
    var body: some View {
        Canvas { ctx, _ in
            let s = GraphicsContext.Shading.color(Color(UIColor.systemGray5))
            func fill(_ r: CGRect, radius: CGFloat = 0) {
                ctx.fill(Path(roundedRect: r, cornerRadius: radius), with: s)
            }
            // Head
            ctx.fill(Path(ellipseIn: CGRect(x:67, y:2,   width:46, height:46)), with: s)
            // Neck
            fill(CGRect(x:81,  y:44,  width:18, height:20), radius:4)
            // Torso
            fill(CGRect(x:36,  y:60,  width:108,height:148),radius:10)
            // Upper arms
            fill(CGRect(x:6,   y:64,  width:32, height:92), radius:8)
            fill(CGRect(x:142, y:64,  width:32, height:92), radius:8)
            // Forearms
            fill(CGRect(x:8,   y:152, width:28, height:78), radius:7)
            fill(CGRect(x:144, y:152, width:28, height:78), radius:7)
            // Hands
            fill(CGRect(x:10,  y:226, width:22, height:28), radius:5)
            fill(CGRect(x:148, y:226, width:22, height:28), radius:5)
            // Upper legs
            fill(CGRect(x:38,  y:204, width:42, height:96), radius:8)
            fill(CGRect(x:100, y:204, width:42, height:96), radius:8)
            // Lower legs
            fill(CGRect(x:40,  y:296, width:36, height:88), radius:7)
            fill(CGRect(x:104, y:296, width:36, height:88), radius:7)
            // Feet
            fill(CGRect(x:36,  y:380, width:44, height:12), radius:4)
            fill(CGRect(x:100, y:380, width:44, height:12), radius:4)
        }
    }
}
