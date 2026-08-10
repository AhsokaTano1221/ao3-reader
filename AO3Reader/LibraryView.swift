import SwiftUI

struct SavedFic: Identifiable {
    let id: UUID
    let title: String
    let author: String
}

struct LibraryView: View {
    // Currently empty as per: "do not put any placeholders for now"
    @State private var savedFics: [SavedFic] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                if savedFics.isEmpty {
                    Text("No Saved Fics")
                        .foregroundColor(.secondary)
                        .font(.headline)
                } else {
                    List(savedFics) { fic in
                        VStack(alignment: .leading) {
                            Text(fic.title)
                                .font(.headline)
                            Text(fic.author)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Library")
        }
    }
}

#Preview {
    LibraryView()
}
