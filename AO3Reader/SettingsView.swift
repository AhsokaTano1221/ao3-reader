import SwiftUI

struct SettingsView: View {
    @State private var isDarkMode = false
    @State private var fontSize: Double = 16.0
    @State private var isAO3User = false // Guest or AO3 user
    @State private var username = "Guest"
    
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
                
                Section(header: Text("Preferences")) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                    
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
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
