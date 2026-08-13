import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("readerFontSize") private var fontSize: Double = 16.0
    @AppStorage("isAO3User") private var isAO3User = false // Guest or AO3 user
    @AppStorage("username") private var username = "Guest"
    
    // Custom App Skins Storage (Hex Strings)
    @AppStorage("theme_backgroundColorHex") private var backgroundColorHex = "#F5F5F3"
    @AppStorage("theme_textColorHex") private var textColorHex = "#222222"
    @AppStorage("theme_accentColorHex") private var accentColorHex = "#B08F54"
    @AppStorage("theme_fontName") private var fontName = "Georgia"
    
    // Bindable Colors initialized from hex storage
    @State private var bgColor = Color(hex: "#F5F5F3")
    @State private var textColor = Color(hex: "#222222")
    @State private var accentColor = Color(hex: "#B08F54")
    
    private var themeBg: Color { Color(hex: backgroundColorHex) }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile")) {
                    HStack(spacing: 15) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading) {
                            Text(isAO3User ? "AO3 User" : "Guest")
                                .font(.headline)
                            if isAO3User {
                                Text("@\(username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("App Skin / Theme")) {
                    ColorPicker("Background Color", selection: $bgColor)
                        .onChange(of: bgColor) { newValue in
                            backgroundColorHex = newValue.toHex()
                        }
                    
                    ColorPicker("Text Color", selection: $textColor)
                        .onChange(of: textColor) { newValue in
                            textColorHex = newValue.toHex()
                        }
                    
                    ColorPicker("Accent Color", selection: $accentColor)
                        .onChange(of: accentColor) { newValue in
                            accentColorHex = newValue.toHex()
                        }
                    
                    Picker("Reader Font", selection: $fontName) {
                        Text("Georgia").tag("Georgia")
                        Text("Baskerville").tag("Baskerville")
                        Text("Palatino").tag("Palatino")
                        Text("Avenir Next").tag("Avenir Next")
                        Text("System").tag("System")
                    }
                }
                
                Section(header: Text("Skin Presets")) {
                    Button(action: {
                        applyPreset(bg: "#F5F5F3", text: "#222222", accent: "#B08F54", font: "Georgia")
                        isDarkMode = false
                    }) {
                        HStack {
                            Text("Classic Gold (Mockup)")
                                .foregroundColor(.primary)
                            Spacer()
                            Circle().fill(Color(hex: "#F5F5F3")).frame(width: 14, height: 14).overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            Circle().fill(Color(hex: "#222222")).frame(width: 14, height: 14)
                            Circle().fill(Color(hex: "#B08F54")).frame(width: 14, height: 14)
                        }
                    }
                    
                    Button(action: {
                        applyPreset(bg: "#FDFBF7", text: "#1A1A1A", accent: "#9E1B1B", font: "Georgia")
                        isDarkMode = false
                    }) {
                        HStack {
                            Text("Warm Parchment")
                                .foregroundColor(.primary)
                            Spacer()
                            Circle().fill(Color(hex: "#FDFBF7")).frame(width: 14, height: 14).overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            Circle().fill(Color(hex: "#1A1A1A")).frame(width: 14, height: 14)
                            Circle().fill(Color(hex: "#9E1B1B")).frame(width: 14, height: 14)
                        }
                    }
                    
                    Button(action: {
                        applyPreset(bg: "#F4ECDB", text: "#2B2519", accent: "#9C6A3B", font: "Baskerville")
                        isDarkMode = false
                    }) {
                        HStack {
                            Text("Sepia Dream")
                                .foregroundColor(.primary)
                            Spacer()
                            Circle().fill(Color(hex: "#F4ECDB")).frame(width: 14, height: 14).overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            Circle().fill(Color(hex: "#2B2519")).frame(width: 14, height: 14)
                            Circle().fill(Color(hex: "#9C6A3B")).frame(width: 14, height: 14)
                        }
                    }
                    
                    Button(action: {
                        applyPreset(bg: "#121214", text: "#E1E1E3", accent: "#B08F54", font: "Georgia")
                        isDarkMode = true
                    }) {
                        HStack {
                            Text("Midnight (Dark)")
                                .foregroundColor(.primary)
                            Spacer()
                            Circle().fill(Color(hex: "#121214")).frame(width: 14, height: 14).overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            Circle().fill(Color(hex: "#E1E1E3")).frame(width: 14, height: 14)
                            Circle().fill(Color(hex: "#B08F54")).frame(width: 14, height: 14)
                        }
                    }
                }
                
                Section(header: Text("Reader Preferences")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Font Size")
                            Spacer()
                            Text("\(Int(fontSize)) pt")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $fontSize, in: 12...28, step: 1)
                    }
                }
                
                Section(header: Text("Account")) {
                    Toggle("Log in to AO3", isOn: $isAO3User)
                        .onChange(of: isAO3User) { newValue in
                            if newValue {
                                username = "AO3ReaderFan"
                            } else {
                                username = "Guest"
                            }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeBg)
            .navigationTitle("Settings")
            .onAppear {
                bgColor = Color(hex: backgroundColorHex)
                textColor = Color(hex: textColorHex)
                accentColor = Color(hex: accentColorHex)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    private func applyPreset(bg: String, text: String, accent: String, font: String) {
        backgroundColorHex = bg
        textColorHex = text
        accentColorHex = accent
        fontName = font
        
        bgColor = Color(hex: bg)
        textColor = Color(hex: text)
        accentColor = Color(hex: accent)
    }
}

#Preview {
    SettingsView()
}
