import SwiftUI

struct HomeView: View {
    @State private var ficURL: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome to AO3 Reader")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter Fic URL")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("https://archiveofourown.org/works/...", text: $ficURL)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal)
                
                Button(action: {
                    // Action will be implemented later
                }) {
                    Text("Load Fic")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Spacer()
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}
