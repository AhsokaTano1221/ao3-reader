import SwiftUI

struct NavigationBarThemeModifier: ViewModifier {
    @AppStorage("theme_fontName") private var fontName = "Georgia"
    @AppStorage("theme_textColorHex") private var textColorHex = "#222222"
    @AppStorage("theme_accentColorHex") private var accentColorHex = "#B08F54"
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                updateAppearance()
            }
            .onChange(of: fontName) { _ in updateAppearance() }
            .onChange(of: textColorHex) { _ in updateAppearance() }
            .onChange(of: accentColorHex) { _ in updateAppearance() }
    }
    
    private func updateAppearance() {
        let uiFont = UIFont(name: fontName, size: 32) ?? UIFont.systemFont(ofSize: 32, weight: .bold)
        let uiInlineFont = UIFont(name: fontName, size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .bold)
        let uiColor = UIColor(Color(hex: textColorHex))
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        // Match navigation bar background with the global theme background color
        let bgHex = UserDefaults.standard.string(forKey: "theme_backgroundColorHex") ?? "#F5F5F3"
        appearance.backgroundColor = UIColor(Color(hex: bgHex))
        
        appearance.largeTitleTextAttributes = [
            .font: uiFont,
            .foregroundColor: uiColor
        ]
        appearance.titleTextAttributes = [
            .font: uiInlineFont,
            .foregroundColor: uiColor
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

extension View {
    func applyNavigationBarTheme() -> some View {
        self.modifier(NavigationBarThemeModifier())
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("theme_accentColorHex") private var accentColorHex = "#B08F54"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .applyNavigationBarTheme()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            SearchView()
                .applyNavigationBarTheme()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            LibraryView()
                .applyNavigationBarTheme()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(2)
            
            SettingsView()
                .applyNavigationBarTheme()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
        .tint(Color(hex: accentColorHex))
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    ContentView()
}
