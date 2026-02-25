import SwiftUI

struct ContentView: View {
    @StateObject private var checkInVM  = CheckInViewModel()
    @StateObject private var occupancyVM = OccupancyViewModel()

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                ZStack {
                    Color(uiColor: .systemBackground)

                    VStack(spacing: 0) {
                        // Nav bar row
                        HStack(alignment: .center) {
                            Text("ArcLive")
                                .font(.title2.weight(.bold))
                            Spacer()
                            BusynessBadge(level: BusynessLevel(count: occupancyVM.count))
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 20)

                        Spacer()

                        // Ring
                        ExerciseRingView(segments: occupancyVM.segments, totalCount: occupancyVM.count)

                        Spacer()

                        // Legend
                        legend

                        Spacer()

                        // Error
                        if let error = checkInVM.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                                .padding(.bottom, 8)
                        }

                        // Check In / Out button
                        checkInButton
                            .padding(.horizontal, 28)
                            .padding(.bottom, 44)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .refreshable {
                await occupancyVM.refresh()
            }
        }
        .sheet(isPresented: $checkInVM.showExercisePicker) {
            ExercisePickerSheet { exercise in
                Task {
                    await checkInVM.checkIn(exercise: exercise)
                    await occupancyVM.refresh()
                }
            }
        }
        .sensoryFeedback(.success, trigger: checkInVM.isCheckedIn)
        .task {
            await occupancyVM.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                await occupancyVM.refresh()
            }
        }
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 20) {
            ForEach(ExerciseType.allCases, id: \.self) { exercise in
                HStack(spacing: 5) {
                    Circle()
                        .fill(exercise.color)
                        .frame(width: 8, height: 8)
                    Text(exercise.abbreviation)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Button

    private var checkInButton: some View {
        Button {
            if checkInVM.isCheckedIn {
                Task {
                    await checkInVM.checkOut()
                    await occupancyVM.refresh()
                }
            } else {
                checkInVM.requestCheckIn()
            }
        } label: {
            Group {
                if checkInVM.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(checkInVM.isCheckedIn ? "Check Out" : "Check In")
                        .font(.title3.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                checkInVM.isCheckedIn ? Color.red : Color.blue,
                in: RoundedRectangle(cornerRadius: 18)
            )
            .foregroundStyle(.white)
            .shadow(
                color: (checkInVM.isCheckedIn ? Color.red : Color.blue).opacity(0.35),
                radius: 12, y: 6
            )
        }
        .disabled(checkInVM.isLoading)
        .animation(.spring(response: 0.3), value: checkInVM.isCheckedIn)
    }
}

// MARK: - Busyness Badge

private struct BusynessBadge: View {
    let level: BusynessLevel

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: level.systemImage)
                .font(.caption.weight(.semibold))
            Text(level.label)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(level.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(level.color.opacity(0.12), in: Capsule())
    }
}
