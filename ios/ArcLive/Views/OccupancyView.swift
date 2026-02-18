import SwiftUI

struct OccupancyView: View {
    @ObservedObject var viewModel: OccupancyViewModel

    var body: some View {
        VStack(spacing: 8) {
            Text("People at the Gym")
                .font(.headline)
                .foregroundStyle(.secondary)

            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(height: 80)
                } else {
                    Text("\(viewModel.count)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .animation(.spring, value: viewModel.count)
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isLoading)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
