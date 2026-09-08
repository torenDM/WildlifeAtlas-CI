import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 48))

                Text("Wildlife Atlas")
                    .font(.largeTitle.bold())

                Text("Project setup complete")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}