import SwiftUI

struct ExercisePickerSheet: View {
    let onSelect: (ExerciseType) -> Void

    // 3 top, 2 bottom centred
    private let topRow: [ExerciseType] = [.chest, .back, .legs]
    private let bottomRow: [ExerciseType] = [.arms, .cardio]

    var body: some View {
        VStack(spacing: 20) {
            // Handle indicator area + title
            VStack(spacing: 4) {
                Text("What are you training?")
                    .font(.title3.weight(.semibold))
                Text("Select to check in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            // Exercise grid
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ForEach(topRow, id: \.self) { exercise in
                        ExerciseTile(exercise: exercise, onTap: onSelect)
                    }
                }
                HStack(spacing: 12) {
                    ForEach(bottomRow, id: \.self) { exercise in
                        ExerciseTile(exercise: exercise, onTap: onSelect)
                            .frame(maxWidth: UIScreen.main.bounds.width / 3 - 20)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .presentationDetents([.height(290)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}

// MARK: - Tile

private struct ExerciseTile: View {
    let exercise: ExerciseType
    let onTap: (ExerciseType) -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            onTap(exercise)
        } label: {
            VStack(spacing: 6) {
                Text(exercise.abbreviation)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text(exercise.fullName)
                    .font(.system(size: 12, weight: .medium))
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(exercise.color, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: exercise.color.opacity(0.4), radius: 8, y: 4)
            .scaleEffect(pressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents(onPress: { pressed = true }, onRelease: { pressed = false })
    }
}

// MARK: - Press gesture helper

private extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}
