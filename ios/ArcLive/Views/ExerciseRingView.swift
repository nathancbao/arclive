import SwiftUI

struct ExerciseRingView: View {
    let segments: [RingSegment]
    let totalCount: Int

    private let ringRadius: CGFloat = 130
    private let lineWidth: CGFloat = 32

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
                .frame(width: ringRadius * 2, height: ringRadius * 2)

            // Colored segments
            ForEach(segments) { segment in
                Circle()
                    .trim(from: segment.start, to: segment.end)
                    .stroke(
                        segment.exercise.color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: ringRadius * 2, height: ringRadius * 2)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: segment.exercise.color.opacity(0.45), radius: 8)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8), value: segment.start)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8), value: segment.end)
            }

            // Abbreviation labels on ring
            ForEach(segments) { segment in
                if segment.fraction >= 0.07 {
                    Text(segment.exercise.abbreviation)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .offset(
                            x: ringRadius * CGFloat(cos(segment.midAngleRadians)),
                            y: ringRadius * CGFloat(sin(segment.midAngleRadians))
                        )
                }
            }

            // Center content
            VStack(spacing: 6) {
                if totalCount == 0 {
                    Text("—")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(totalCount)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.5), value: totalCount)
                }
                Text(totalCount == 1 ? "person" : "people")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.5)
            }
        }
        .frame(width: ringRadius * 2 + lineWidth, height: ringRadius * 2 + lineWidth)
    }
}
