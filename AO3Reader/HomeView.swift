import SwiftUI

struct HomeView: View {
    @ObservedObject private var libraryManager = LibraryManager.shared
    @State private var selectedFic: Fic?
    
    // User login details synced from Settings
    @AppStorage("isAO3User") private var isAO3User = false
    @AppStorage("username") private var username = "Guest"
    
    // Custom App Skins Storage (Hex Strings)
    @AppStorage("theme_backgroundColorHex") private var backgroundColorHex = "#F5F5F3"
    @AppStorage("theme_textColorHex") private var textColorHex = "#222222"
    @AppStorage("theme_accentColorHex") private var accentColorHex = "#B08F54"
    @AppStorage("theme_fontName") private var fontName = "Georgia"
    
    private var themeBg: Color { Color(hex: backgroundColorHex) }
    private var themeText: Color { Color(hex: textColorHex) }
    private var themeAccent: Color { Color(hex: accentColorHex) }
    
    func titleFont(size: CGFloat) -> Font {
        if fontName == "System" {
            return .system(size: size).bold()
        } else {
            return .custom(fontName, size: size).bold()
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Profile Header Row (Synchronized with Settings)
                    HStack(spacing: 16) {
                        // Avatar Circle
                        Circle()
                            .fill(themeAccent.opacity(0.12))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(username.prefix(1).uppercased())
                                    .font(titleFont(size: 28))
                                    .foregroundColor(themeAccent)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(username)
                                .font(titleFont(size: 24))
                                .foregroundColor(themeText)
                            
                            Text(isAO3User ? "Signed in to AO3" : "Reading as Guest")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // WHERE YOU LEFT OFF Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WHERE YOU LEFT OFF")
                            .font(.caption2)
                            .tracking(1)
                            .foregroundColor(.secondary)
                            .fontWeight(.semibold)
                        
                        if let firstFic = libraryManager.savedFics.first {
                            Button(action: {
                                selectedFic = firstFic
                            }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("CHAPTER 1 · SAVED OFFLINE")
                                        .font(.caption2)
                                        .foregroundColor(themeAccent)
                                        .fontWeight(.medium)
                                    
                                    Text(firstFic.title)
                                        .font(titleFont(size: 18))
                                        .foregroundColor(themeText)
                                        .multilineTextAlignment(.leading)
                                    
                                    Text(firstFic.author)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    // Progress Bar
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.gray.opacity(0.15))
                                                .frame(height: 4)
                                            Capsule()
                                                .fill(themeAccent)
                                                .frame(width: geo.size.width * 0.48, height: 4)
                                        }
                                    }
                                    .frame(height: 4)
                                    .padding(.vertical, 4)
                                    
                                    HStack {
                                        Text("1 of \(firstFic.chapters.count) chapter\(firstFic.chapters.count == 1 ? "" : "s")")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("48%")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(16)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("No active reading session")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Search or import works to begin reading.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .padding(.top, 16)
            }
            .background(themeBg)
            .navigationTitle("Reading Room")
            .fullScreenCover(item: $selectedFic) { fic in
                ReaderView(fic: fic)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundColor(themeAccent)
                    }
                }
            }
            .onAppear {
                libraryManager.loadLibrary()
            }
        }
    }
}

#Preview {
    HomeView()
}
