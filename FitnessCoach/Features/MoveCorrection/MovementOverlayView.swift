//
//  MovementOverlayView.swift
//  FitnessCoach
//

import SwiftUI
import Vision

struct MovementOverlayView: View {
    let points: [JointOverlayPoint]

    private let jointConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)
    ]

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for connection in jointConnections {
                    guard let first = point(for: connection.0), let second = point(for: connection.1) else { continue }

                    var path = Path()
                    path.move(to: scaledPoint(first.point, in: size))
                    path.addLine(to: scaledPoint(second.point, in: size))
                    context.stroke(path, with: .color(.green.opacity(0.9)), lineWidth: 3)
                }

                for point in points {
                    let rect = CGRect(
                        origin: CGPoint(
                            x: scaledPoint(point.point, in: size).x - 4,
                            y: scaledPoint(point.point, in: size).y - 4
                        ),
                        size: CGSize(width: 8, height: 8)
                    )

                    context.fill(Path(ellipseIn: rect), with: .color(.white))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .allowsHitTesting(false)
    }

    private func point(for joint: VNHumanBodyPoseObservation.JointName) -> JointOverlayPoint? {
        points.first { $0.joint == joint }
    }

    private func scaledPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }
}
