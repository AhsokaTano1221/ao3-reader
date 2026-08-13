import SwiftUI

struct LibraryView: View {
    @ObservedObject private var libraryManager = LibraryManager.shared
    @State private var selectedFic: Fic?
    
    // Custom App Skins Storage (Hex Strings)
    @AppStorage("theme_backgroundColorHex") private var backgroundColorHex = "#F5F5F3"
    @AppStorage("theme_textColorHex") private var textColorHex = "#222222"
    @AppStorage("theme_accentColorHex") private var accentColorHex = "#B08F54"
    @AppStorage("theme_fontName") private var fontName = "Georgia"
    
    private var themeBg: Color { Color(hex: backgroundColorHex) }
    private var themeText: Color { Color(hex: textColorHex) }
    private var themeAccent: Color { Color(hex: accentColorHex) }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if libraryManager.savedFics.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 64))
                            .foregroundColor(themeAccent.opacity(0.6))
                        
                        Text("Your Library is Empty")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Search for fics on the Search tab and tap the bookmark icon to save them offline.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxHeight: .infinity)
                    .background(themeBg)
                } else {
                    List {
                        ForEach(libraryManager.savedFics) { fic in
                            Button(action: {
                                selectedFic = fic
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(fic.title)
                                        .font(fontName == "System" ? .headline : .custom(fontName, size: 18).bold())
                                        .foregroundColor(themeText)
                                        .lineLimit(1)
                                    
                                    Text("by \(fic.author)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    
                                    Text("\(fic.chapters.count) chapter\(fic.chapters.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(themeAccent)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteFics)
                    }
                    .scrollContentBackground(.hidden)
                    .background(themeBg)
                }
            }
            .navigationTitle("Library")
            .fullScreenCover(item: $selectedFic) { fic in
                ReaderView(fic: fic)
            }
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
