import SwiftUI

struct CheckInView: View {
    @ObservedObject var viewModel: CheckInViewModel
    /// Called after a successful check-in or check-out so the occupancy view can refresh.
    var onStateChange: () async -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Status label
            Label(
                viewModel.isCheckedIn ? "You are checked in" : "You are not checked in",
                systemImage: viewModel.isCheckedIn ? "checkmark.circle.fill" : "xmark.circle"
            )
            .font(.subheadline)
            .foregroundStyle(viewModel.isCheckedIn ? .green : .secondary)
            .symbolEffect(.bounce, value: viewModel.isCheckedIn)

            // Action button
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.large)
            } else {
                Button {
                    Task {
                        if viewModel.isCheckedIn {
                            await viewModel.checkOut()
                        } else {
                            await viewModel.checkIn()
                        }
                        await onStateChange()
                    }
                } label: {
                    Text(viewModel.isCheckedIn ? "Check Out" : "Check In")
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isCheckedIn ? .red : .green)
                .controlSize(.large)
            }

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .animation(.default, value: viewModel.isCheckedIn)
        .animation(.default, value: viewModel.errorMessage)
    }
}
