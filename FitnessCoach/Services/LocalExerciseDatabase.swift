//
//  LocalExerciseDatabase.swift
//  FitnessCoach
//
//  Replaces the API Ninjas exercises endpoint (blocked on free tier).
//  Returns the same [Exercise] type so all existing views work unchanged.
//

import Foundation

struct LocalExerciseDatabase {

    static func exercises(muscle: String?, difficulty: String?) -> [Exercise] {
        var result = all
        if let m = muscle, m != "all" {
            // "back" is an alias for all back-related sub-groups
            let targets: [String]
            switch m.lowercased() {
            case "back": targets = ["lats", "middle_back", "lower_back"]
            default:     targets = [m.lowercased()]
            }
            result = result.filter { targets.contains($0.muscle.lowercased()) }
        }
        if let d = difficulty, d != "all" {
            result = result.filter { $0.difficulty.lowercased() == d.lowercased() }
        }
        return result
    }

    // MARK: - Full exercise list

    private static let all: [Exercise] = [

        // CHEST
        Exercise(name: "Barbell Bench Press",          type: "strength",    muscle: "chest",       equipment: "barbell",    difficulty: "intermediate", instructions: "Lie on a flat bench. Grip the barbell slightly wider than shoulder-width. Lower the bar to your chest under control, then press it back up to full arm extension."),
        Exercise(name: "Dumbbell Bench Press",          type: "strength",    muscle: "chest",       equipment: "dumbbell",   difficulty: "beginner",     instructions: "Lie on a flat bench holding a dumbbell in each hand at chest level. Press the dumbbells up until your arms are fully extended, then lower with control."),
        Exercise(name: "Incline Barbell Press",         type: "strength",    muscle: "chest",       equipment: "barbell",    difficulty: "intermediate", instructions: "Set the bench to a 30-45° incline. Perform a bench press from this angle to target the upper chest."),
        Exercise(name: "Push-Up",                       type: "strength",    muscle: "chest",       equipment: "bodyweight", difficulty: "beginner",     instructions: "Place hands shoulder-width apart on the floor. Lower your chest to the ground while keeping your body straight, then push back up."),
        Exercise(name: "Cable Chest Fly",               type: "strength",    muscle: "chest",       equipment: "cable",      difficulty: "beginner",     instructions: "Stand between two cable stations set at chest height. With a slight bend in your elbows, bring the handles together in front of your chest in an arcing motion."),
        Exercise(name: "Dumbbell Chest Fly",            type: "strength",    muscle: "chest",       equipment: "dumbbell",   difficulty: "beginner",     instructions: "Lie on a flat bench with dumbbells held directly above your chest. Lower the weights out to the sides with a slight elbow bend, then bring them back together."),
        Exercise(name: "Decline Bench Press",           type: "strength",    muscle: "chest",       equipment: "barbell",    difficulty: "intermediate", instructions: "Set the bench at a slight decline. Perform a bench press from this angle to target the lower chest."),
        Exercise(name: "Chest Dip",                     type: "strength",    muscle: "chest",       equipment: "bodyweight", difficulty: "intermediate", instructions: "On parallel bars, lean your torso forward slightly and lower yourself until your upper arms are parallel to the floor, then push back up."),

        // LATS / BACK
        Exercise(name: "Pull-Up",                       type: "strength",    muscle: "lats",        equipment: "bodyweight", difficulty: "intermediate", instructions: "Hang from a pull-up bar with an overhand grip wider than shoulder-width. Pull yourself up until your chin clears the bar, then lower with control."),
        Exercise(name: "Chin-Up",                       type: "strength",    muscle: "lats",        equipment: "bodyweight", difficulty: "beginner",     instructions: "Hang from a pull-up bar with an underhand grip. Pull yourself up until your chin clears the bar, engaging the biceps and lats."),
        Exercise(name: "Lat Pulldown",                  type: "strength",    muscle: "lats",        equipment: "cable",      difficulty: "beginner",     instructions: "Sit at a lat pulldown machine. Grip the bar wider than shoulder-width. Pull the bar down to your upper chest while keeping your torso upright."),
        Exercise(name: "Seated Cable Row",              type: "strength",    muscle: "middle_back",  equipment: "cable",      difficulty: "beginner",     instructions: "Sit at a cable row station with feet against the pad. Pull the handle to your lower ribcage, squeezing your shoulder blades together, then extend arms fully."),
        Exercise(name: "Barbell Bent-Over Row",         type: "strength",    muscle: "middle_back",  equipment: "barbell",    difficulty: "intermediate", instructions: "Hinge at the hips to bring your torso roughly parallel to the floor. Pull the barbell to your lower ribcage, squeezing your back at the top."),
        Exercise(name: "Dumbbell Single-Arm Row",       type: "strength",    muscle: "lats",        equipment: "dumbbell",   difficulty: "beginner",     instructions: "Place one hand and the same-side knee on a bench for support. Row the dumbbell on the opposite side to your hip, keeping your elbow close to your body."),
        Exercise(name: "T-Bar Row",                     type: "strength",    muscle: "middle_back",  equipment: "barbell",    difficulty: "intermediate", instructions: "Stand over the T-bar, hinge at the hips, and row the weight to your lower chest, retracting your shoulder blades at the top."),
        Exercise(name: "Straight-Arm Pulldown",         type: "strength",    muscle: "lats",        equipment: "cable",      difficulty: "beginner",     instructions: "Stand at a high cable. With arms nearly straight, pull the bar down to your thighs using only your lats, then return with control."),

        // MIDDLE / LOWER BACK
        Exercise(name: "Deadlift",                      type: "strength",    muscle: "lower_back",  equipment: "barbell",    difficulty: "expert",       instructions: "Stand with feet hip-width apart and the barbell over mid-foot. Hinge and grip the bar, then drive through your legs and hips to stand upright. Lower with control."),
        Exercise(name: "Romanian Deadlift",             type: "strength",    muscle: "lower_back",  equipment: "barbell",    difficulty: "intermediate", instructions: "Hold the bar at hip level. Hinge at the hips, pushing them back while keeping the bar close to your legs. Lower until you feel a strong hamstring stretch, then drive hips forward to stand."),
        Exercise(name: "Back Extension (Hyperextension)", type: "strength", muscle: "lower_back",  equipment: "bodyweight", difficulty: "beginner",     instructions: "Lie face-down on a hyperextension bench with your hips at the pad's edge. Lower your torso toward the floor, then raise it until your body is straight."),
        Exercise(name: "Good Morning",                  type: "strength",    muscle: "lower_back",  equipment: "barbell",    difficulty: "intermediate", instructions: "Stand with a barbell on your upper back. Hinge at the hips with a slight knee bend until your torso is nearly parallel to the floor, then return upright."),

        // BICEPS
        Exercise(name: "Barbell Curl",                  type: "strength",    muscle: "biceps",      equipment: "barbell",    difficulty: "beginner",     instructions: "Stand holding a barbell with an underhand grip at hip level. Curl the bar to shoulder height while keeping your elbows pinned at your sides, then lower with control."),
        Exercise(name: "Dumbbell Curl",                 type: "strength",    muscle: "biceps",      equipment: "dumbbell",   difficulty: "beginner",     instructions: "Hold dumbbells at your sides. Curl one or both to shoulder height, rotating your palms to face up at the top, then lower with control."),
        Exercise(name: "Hammer Curl",                   type: "strength",    muscle: "biceps",      equipment: "dumbbell",   difficulty: "beginner",     instructions: "Hold dumbbells with a neutral grip (palms facing each other). Curl the weights to shoulder height without rotating your wrists."),
        Exercise(name: "Preacher Curl",                 type: "strength",    muscle: "biceps",      equipment: "barbell",    difficulty: "beginner",     instructions: "Rest your upper arms on a preacher bench pad. Curl the bar from full extension to chin height, then lower slowly."),
        Exercise(name: "Concentration Curl",            type: "strength",    muscle: "biceps",      equipment: "dumbbell",   difficulty: "beginner",     instructions: "Sit on a bench. Brace your upper arm against your inner thigh. Curl the dumbbell to your shoulder, squeezing at the top, then lower."),
        Exercise(name: "Cable Curl",                    type: "strength",    muscle: "biceps",      equipment: "cable",      difficulty: "beginner",     instructions: "Attach a straight bar to a low cable. Curl the bar to shoulder height, keeping your elbows stationary at your sides."),

        // TRICEPS
        Exercise(name: "Triceps Pushdown",              type: "strength",    muscle: "triceps",     equipment: "cable",      difficulty: "beginner",     instructions: "Attach a bar or rope to a high cable. With elbows pinned at your sides, push the attachment down until your arms are fully extended, then allow a controlled return."),
        Exercise(name: "Skull Crusher",                 type: "strength",    muscle: "triceps",     equipment: "barbell",    difficulty: "intermediate", instructions: "Lie on a flat bench. Hold the barbell above your forehead with straight arms. Bend at the elbows to lower the bar toward your forehead, then press back up."),
        Exercise(name: "Overhead Triceps Extension",    type: "strength",    muscle: "triceps",     equipment: "dumbbell",   difficulty: "beginner",     instructions: "Hold one dumbbell with both hands overhead. Lower it behind your head by bending the elbows, then press back up."),
        Exercise(name: "Triceps Dip",                   type: "strength",    muscle: "triceps",     equipment: "bodyweight", difficulty: "intermediate", instructions: "On parallel bars, keep your torso upright. Lower yourself until your upper arms are parallel to the floor, then push back up."),
        Exercise(name: "Close-Grip Bench Press",        type: "strength",    muscle: "triceps",     equipment: "barbell",    difficulty: "intermediate", instructions: "Lie on a flat bench. Grip the barbell with hands about shoulder-width. Perform a bench press with elbows tucked close to your body to target the triceps."),
        Exercise(name: "Diamond Push-Up",               type: "strength",    muscle: "triceps",     equipment: "bodyweight", difficulty: "beginner",     instructions: "Form a diamond shape with your hands directly under your chest. Perform a push-up, keeping elbows close to your body."),

        // SHOULDERS
        Exercise(name: "Overhead Press",                type: "strength",    muscle: "shoulders",   equipment: "barbell",    difficulty: "intermediate", instructions: "Stand with the barbell at shoulder height. Press it overhead to full arm extension, then lower back to shoulder level."),
        Exercise(name: "Dumbbell Shoulder Press",       type: "strength",    muscle: "shoulders",   equipment: "dumbbell",   difficulty: "beginner",     instructions: "Hold dumbbells at shoulder height with palms facing forward. Press them overhead until arms are extended, then lower with control."),
        Exercise(name: "Lateral Raise",                 type: "strength",    muscle: "shoulders",   equipment: "dumbbell",   difficulty: "beginner",     instructions: "Hold dumbbells at your sides. Raise them out to the sides until your arms reach shoulder height, then lower with control."),
        Exercise(name: "Front Raise",                   type: "strength",    muscle: "shoulders",   equipment: "dumbbell",   difficulty: "beginner",     instructions: "Hold dumbbells in front of your thighs. Raise them forward to shoulder height with arms nearly straight, then lower with control."),
        Exercise(name: "Reverse Fly",                   type: "strength",    muscle: "shoulders",   equipment: "dumbbell",   difficulty: "beginner",     instructions: "Hinge forward at the hips. Hold dumbbells hanging below your chest. Raise them out to your sides, squeezing your rear delts, then lower."),
        Exercise(name: "Arnold Press",                  type: "strength",    muscle: "shoulders",   equipment: "dumbbell",   difficulty: "intermediate", instructions: "Hold dumbbells at shoulder height with palms facing you. As you press up, rotate your palms forward so they face away at the top, then reverse on the way down."),
        Exercise(name: "Face Pull",                     type: "strength",    muscle: "shoulders",   equipment: "cable",      difficulty: "beginner",     instructions: "Attach a rope to a high cable. Pull it toward your face with elbows high, flaring them out at the end of the movement, then return."),

        // TRAPS
        Exercise(name: "Barbell Shrug",                 type: "strength",    muscle: "traps",       equipment: "barbell",    difficulty: "beginner",     instructions: "Hold a barbell in front of your thighs. Shrug your shoulders straight up as high as possible, hold for a moment, then lower."),
        Exercise(name: "Dumbbell Shrug",                type: "strength",    muscle: "traps",       equipment: "dumbbell",   difficulty: "beginner",     instructions: "Hold dumbbells at your sides. Shrug your shoulders straight up as high as possible, hold briefly, then lower."),

        // FOREARMS
        Exercise(name: "Wrist Curl",                    type: "strength",    muscle: "forearms",    equipment: "barbell",    difficulty: "beginner",     instructions: "Sit and rest your forearms on your thighs with palms up. Hold the barbell and curl your wrists upward, then lower fully."),
        Exercise(name: "Reverse Wrist Curl",            type: "strength",    muscle: "forearms",    equipment: "barbell",    difficulty: "beginner",     instructions: "Sit and rest your forearms on your thighs with palms down. Hold the barbell and curl your wrists upward, then lower fully."),
        Exercise(name: "Farmer's Walk",                 type: "strength",    muscle: "forearms",    equipment: "dumbbell",   difficulty: "beginner",     instructions: "Hold heavy dumbbells at your sides. Walk for a set distance or time while keeping your core braced and grip tight."),

        // QUADRICEPS
        Exercise(name: "Barbell Back Squat",            type: "strength",    muscle: "quadriceps",  equipment: "barbell",    difficulty: "intermediate", instructions: "Place the barbell on your upper back. Stand with feet shoulder-width apart. Squat down until your thighs are parallel to the floor, then drive through your heels to stand."),
        Exercise(name: "Front Squat",                   type: "strength",    muscle: "quadriceps",  equipment: "barbell",    difficulty: "expert",       instructions: "Hold the barbell across the front of your shoulders. Squat down keeping your torso upright, then drive up to standing."),
        Exercise(name: "Leg Press",                     type: "strength",    muscle: "quadriceps",  equipment: "machine",    difficulty: "beginner",     instructions: "Sit in the leg press machine. Place feet shoulder-width on the platform. Lower the weight toward your chest, then press back to near-full extension."),
        Exercise(name: "Leg Extension",                 type: "strength",    muscle: "quadriceps",  equipment: "machine",    difficulty: "beginner",     instructions: "Sit in the leg extension machine with the pad on your lower shins. Extend your legs to full extension, squeeze, then lower with control."),
        Exercise(name: "Lunge",                         type: "strength",    muscle: "quadriceps",  equipment: "dumbbell",   difficulty: "beginner",     instructions: "Hold dumbbells at your sides. Step forward with one foot and lower your back knee toward the floor. Push through your front heel to return to standing."),
        Exercise(name: "Bulgarian Split Squat",         type: "strength",    muscle: "quadriceps",  equipment: "dumbbell",   difficulty: "intermediate", instructions: "Place your rear foot on a bench. Hold dumbbells at your sides. Lower your front knee until your thigh is parallel to the floor, then press back up."),
        Exercise(name: "Bodyweight Squat",              type: "strength",    muscle: "quadriceps",  equipment: "bodyweight", difficulty: "beginner",     instructions: "Stand with feet shoulder-width apart. Lower into a squat keeping your chest up and knees tracking over your toes, then drive through your heels to stand."),
        Exercise(name: "Hack Squat",                    type: "strength",    muscle: "quadriceps",  equipment: "machine",    difficulty: "intermediate", instructions: "Position yourself in the hack squat machine with shoulders under the pads. Lower until your thighs are parallel, then press back up."),

        // HAMSTRINGS
        Exercise(name: "Lying Leg Curl",                type: "strength",    muscle: "hamstrings",  equipment: "machine",    difficulty: "beginner",     instructions: "Lie face-down on the leg curl machine. Curl your heels toward your glutes, squeezing the hamstrings at the top, then lower with control."),
        Exercise(name: "Seated Leg Curl",               type: "strength",    muscle: "hamstrings",  equipment: "machine",    difficulty: "beginner",     instructions: "Sit in the leg curl machine. Pull the pad toward the back of your thighs, squeezing at the bottom, then extend with control."),
        Exercise(name: "Stiff-Leg Deadlift",            type: "strength",    muscle: "hamstrings",  equipment: "barbell",    difficulty: "intermediate", instructions: "Stand with the barbell at hip level. Keeping legs nearly straight, hinge at the hips and lower the bar along your legs until you feel a strong hamstring stretch, then drive hips forward to stand."),
        Exercise(name: "Nordic Hamstring Curl",         type: "strength",    muscle: "hamstrings",  equipment: "bodyweight", difficulty: "expert",       instructions: "Kneel with your ankles secured. Slowly lower your body toward the floor by extending your knees, using your hamstrings to control the descent. Push with your hands to return."),

        // GLUTES
        Exercise(name: "Hip Thrust",                    type: "strength",    muscle: "glutes",      equipment: "barbell",    difficulty: "intermediate", instructions: "Sit with your upper back against a bench, barbell across your hips. Plant your feet flat and drive your hips up until your body forms a straight line, then lower."),
        Exercise(name: "Glute Bridge",                  type: "strength",    muscle: "glutes",      equipment: "bodyweight", difficulty: "beginner",     instructions: "Lie on your back with knees bent. Drive your hips toward the ceiling by squeezing your glutes, hold briefly at the top, then lower."),
        Exercise(name: "Cable Kickback",                type: "strength",    muscle: "glutes",      equipment: "cable",      difficulty: "beginner",     instructions: "Attach an ankle cuff to a low cable. Stand facing the machine and kick your working leg back and up, squeezing the glute at the top, then return."),
        Exercise(name: "Sumo Squat",                    type: "strength",    muscle: "glutes",      equipment: "dumbbell",   difficulty: "beginner",     instructions: "Stand with feet wide and toes pointed out. Hold a dumbbell with both hands between your legs. Squat down, keeping your chest up, then drive through your heels to stand."),
        Exercise(name: "Step-Up",                       type: "strength",    muscle: "glutes",      equipment: "dumbbell",   difficulty: "beginner",     instructions: "Hold dumbbells at your sides. Step onto a box or bench with one foot, drive through that heel to bring your body up, then step down and alternate."),

        // CALVES
        Exercise(name: "Standing Calf Raise",           type: "strength",    muscle: "calves",      equipment: "machine",    difficulty: "beginner",     instructions: "Stand on the edge of a step or calf raise machine. Rise onto your toes as high as possible, hold briefly, then lower your heels below the step level."),
        Exercise(name: "Seated Calf Raise",             type: "strength",    muscle: "calves",      equipment: "machine",    difficulty: "beginner",     instructions: "Sit in the seated calf raise machine with the pad on your lower thighs. Rise onto your toes, hold briefly, then lower fully."),
        Exercise(name: "Donkey Calf Raise",             type: "strength",    muscle: "calves",      equipment: "machine",    difficulty: "beginner",     instructions: "Bend forward and place your forearms on a support. Rise onto your toes as high as possible, hold briefly, then lower."),

        // ABDOMINALS
        Exercise(name: "Crunch",                        type: "strength",    muscle: "abdominals",  equipment: "bodyweight", difficulty: "beginner",     instructions: "Lie on your back with knees bent. Place hands behind your head. Contract your abs to lift your shoulder blades off the floor, then lower with control."),
        Exercise(name: "Plank",                         type: "strength",    muscle: "abdominals",  equipment: "bodyweight", difficulty: "beginner",     instructions: "Hold a push-up position with your forearms on the floor. Keep your body in a straight line from head to heels, bracing your core throughout."),
        Exercise(name: "Leg Raise",                     type: "strength",    muscle: "abdominals",  equipment: "bodyweight", difficulty: "intermediate", instructions: "Lie flat on your back. Keeping legs straight, raise them to 90° by contracting your lower abs, then lower them with control without touching the floor."),
        Exercise(name: "Russian Twist",                 type: "strength",    muscle: "abdominals",  equipment: "bodyweight", difficulty: "beginner",     instructions: "Sit with knees bent and torso at 45°. Clasp your hands or hold a weight. Rotate your torso from side to side, touching the floor (or nearly) with each twist."),
        Exercise(name: "Bicycle Crunch",                type: "strength",    muscle: "abdominals",  equipment: "bodyweight", difficulty: "beginner",     instructions: "Lie on your back with hands behind your head. Bring one knee to your chest while rotating your opposite elbow toward it. Alternate sides in a cycling motion."),
        Exercise(name: "Cable Crunch",                  type: "strength",    muscle: "abdominals",  equipment: "cable",      difficulty: "beginner",     instructions: "Kneel in front of a high cable with a rope attachment. Hold the rope behind your head and crunch your elbows toward your knees, then return."),
        Exercise(name: "Ab Rollout",                    type: "strength",    muscle: "abdominals",  equipment: "bodyweight", difficulty: "intermediate", instructions: "Kneel and hold an ab wheel with arms extended. Roll forward as far as you can while maintaining a straight back, then contract your abs to pull back to the start."),
        Exercise(name: "Mountain Climber",              type: "cardio",      muscle: "abdominals",  equipment: "bodyweight", difficulty: "beginner",     instructions: "Start in a push-up position. Drive one knee toward your chest, then quickly alternate legs in a running motion while keeping your hips level."),

        // ADDUCTORS / ABDUCTORS
        Exercise(name: "Hip Adduction Machine",         type: "strength",    muscle: "adductors",   equipment: "machine",    difficulty: "beginner",     instructions: "Sit in the hip adduction machine with pads on the inside of your knees. Push your legs together against the resistance, then open them with control."),
        Exercise(name: "Hip Abduction Machine",         type: "strength",    muscle: "abductors",   equipment: "machine",    difficulty: "beginner",     instructions: "Sit in the hip abduction machine with pads on the outside of your knees. Push your legs apart against the resistance, then bring them together with control."),
        Exercise(name: "Side-Lying Hip Abduction",      type: "strength",    muscle: "abductors",   equipment: "bodyweight", difficulty: "beginner",     instructions: "Lie on your side. Lift your top leg upward while keeping it straight, squeeze at the top, then lower with control."),

        // NECK
        Exercise(name: "Neck Flexion",                  type: "strength",    muscle: "neck",        equipment: "bodyweight", difficulty: "beginner",     instructions: "Sit upright. Slowly tilt your head forward, bringing your chin toward your chest. Hold briefly, then return to neutral."),
    ]
}
