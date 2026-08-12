import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("AO3 Reader")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("Home page is blank for now.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                Spacer()
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}
