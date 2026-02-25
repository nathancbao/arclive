import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool

    private let features: [(icon: String, title: String, detail: String)] = [
        ("chart.bar.fill",    "Live Occupancy",   "See how busy the gym is right now, broken down by exercise."),
        ("checkmark.circle.fill", "Check In & Out", "Log your visits with one tap. No account needed."),
        ("trophy.fill",       "Track Your Stats",  "View your visit history, streaks, and favourite exercises."),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.07, blue: 0.12), Color(red: 0.05, green: 0.05, blue: 0.10)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.18))
                        .frame(width: 96, height: 96)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(Color.blue)
                }
                .padding(.bottom, 28)

                Text("ArcLive")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
                Text("Your gym, live.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.top, 4)

                Spacer()

                // Feature list
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(features, id: \.title) { feature in
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: feature.icon)
                                .font(.title2)
                                .foregroundStyle(Color.blue)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(feature.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                        }
                    }
                }
                .padding(.horizontal, 36)

                Spacer()

                // CTA
                Button {
                    hasSeenOnboarding = true
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                        .shadow(color: Color.blue.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
    }
}
