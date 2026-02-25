import SwiftUI

@main
struct ArcLiveApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
            }
            .fullScreenCover(isPresented: Binding(
                get:  { !hasSeenOnboarding },
                set:  { if !$0 { hasSeenOnboarding = true } }
            )) {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            }
        }
    }
}
