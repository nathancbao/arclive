import SwiftUI

struct ContentView: View {
    @StateObject private var checkInVM = CheckInViewModel()
    @StateObject private var occupancyVM = OccupancyViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    OccupancyView(viewModel: occupancyVM)
                    CheckInView(viewModel: checkInVM) {
                        // Refresh occupancy after any check-in or check-out
                        await occupancyVM.refresh()
                    }
                }
                .padding()
            }
            .navigationTitle("ArcLive")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await occupancyVM.refresh()
            }
        }
    }
}
