#!/usr/bin/env python3
"""
GenerateSquatModel.py
Generates SquatFormClassifier.mlmodel for the FitnessCoach iOS app.

Install dependencies once:
    pip3 install coremltools scikit-learn numpy

Run:
    python3 Scripts/GenerateSquatModel.py

Then in Xcode:
    1. Drag SquatFormClassifier.mlmodel into the FitnessCoach group
    2. Make sure it's added to the app target
    3. Build — Xcode compiles it to SquatFormClassifier.mlmodelc automatically

Model inputs  (from Vision joint positions via MovementAnalyzer):
    knee_angle           : Double  — avg hip-knee-ankle angle in degrees
                                     lower = deeper squat (good is ≤ 95°)
    knee_alignment_ratio : Double  — knee_width / ankle_width
                                     below 0.75 = valgus (knees caving in)

Model output:
    formClass : String  — "goodForm" | "rangeIncomplete" | "kneeAlignment"
"""

import numpy as np
from sklearn.tree import DecisionTreeClassifier

try:
    import coremltools as ct
except ImportError:
    raise SystemExit("Run:  pip3 install coremltools scikit-learn numpy")

# ---------------------------------------------------------------------------
# Training data: [knee_angle, knee_alignment_ratio]
# ---------------------------------------------------------------------------
samples = [
    # Good form — deep squat AND knees tracking over toes
    (88,  0.95), (90,  1.00), (85,  0.90), (92,  0.88),
    (80,  1.02), (78,  0.96), (93,  0.94), (87,  1.05),

    # Range incomplete — not deep enough (knee_angle > 95°)
    (120, 0.95), (115, 1.00), (130, 0.92), (110, 0.88),
    (125, 0.98), (135, 1.03), (108, 0.91), (118, 0.97),

    # Knee alignment — valgus regardless of depth
    (88,  0.65), (90,  0.60), (95,  0.70), (85,  0.68),
    (92,  0.72), (82,  0.64), (88,  0.58), (91,  0.67),
    # Valgus even when not deep (both problems; knee alignment takes priority)
    (115, 0.63), (120, 0.69), (110, 0.71),
]

labels = (
    ["goodForm"]        * 8 +
    ["rangeIncomplete"] * 8 +
    ["kneeAlignment"]   * 11
)

X = np.array(samples, dtype=np.float64)
y = np.array(labels)

clf = DecisionTreeClassifier(max_depth=5, random_state=42)
clf.fit(X, y)
print(f"Training accuracy: {clf.score(X, y):.1%}")

# ---------------------------------------------------------------------------
# Convert to CoreML
# ---------------------------------------------------------------------------
coreml_model = ct.converters.sklearn.convert(
    clf,
    input_features=[
        ("knee_angle",           ct.models.datatypes.Double()),
        ("knee_alignment_ratio", ct.models.datatypes.Double()),
    ],
    output_feature_names="formClass",
)

coreml_model.short_description = (
    "Classifies squat form from Vision joint angles. "
    "Outputs: goodForm | rangeIncomplete | kneeAlignment"
)
coreml_model.input_description["knee_angle"] = (
    "Average hip-knee-ankle angle in degrees. Lower = deeper squat."
)
coreml_model.input_description["knee_alignment_ratio"] = (
    "Knee width divided by ankle width. Below 0.75 indicates valgus."
)
coreml_model.output_description["formClass"] = (
    "Form category: goodForm, rangeIncomplete, or kneeAlignment."
)

output_path = "SquatFormClassifier.mlmodel"
coreml_model.save(output_path)
print(f"Saved → {output_path}")
print("Drag this file into your Xcode project (FitnessCoach group) and build.")
