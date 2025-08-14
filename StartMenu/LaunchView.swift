import SwiftUI

struct LaunchView: View {
    @EnvironmentObject private var coordinator: StartupCoordinator

    var body: some View {
        ZStack {
            // Background image
            AsyncImage(url: coordinator.backgroundImageURL) { phase in
                switch phase {
                case .empty:
                    Color.black.ignoresSafeArea()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                case .failure:
                    Color.black.ignoresSafeArea()
                @unknown default:
                    Color.black.ignoresSafeArea()
                }
            }

            // Foreground loading animation
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.4)
                if let desc = coordinator.descriptionText {
                    Text(desc)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
