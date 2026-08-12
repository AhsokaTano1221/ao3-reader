import SwiftUI

struct LibraryView: View {
    @ObservedObject private var libraryManager = LibraryManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if libraryManager.savedFics.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text("Your Library is Empty")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Search for fics on the Home tab and tap the bookmark icon to save them offline.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(libraryManager.savedFics) { fic in
                            NavigationLink(destination: ReaderView(fic: fic)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(fic.title)
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Text("by \(fic.author)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    
                                    Text("\(fic.chapters.count) chapter\(fic.chapters.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteFics)
                    }
                }
            }
            .navigationTitle("Library")
            .onAppear {
                libraryManager.loadLibrary()
            }
        }
    }
    
    private func deleteFics(at offsets: IndexSet) {
        for index in offsets {
            let fic = libraryManager.savedFics[index]
            libraryManager.deleteFic(fic)
        }
    }
}

#Preview {
    LibraryView()
}
