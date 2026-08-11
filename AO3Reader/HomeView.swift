import SwiftUI

struct HomeView: View {
    @State private var ficURL: String = ""
    @State private var isLoading = false
    @State private var parsedFic: Fic? = nil
    @State private var navigateToReader = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    
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
                        .disabled(isLoading)
                }
                .padding(.horizontal)
                
                Button(action: {
                    loadFic()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 8)
                        }
                        Text(isLoading ? "Loading Fic..." : "Load Fic")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ficURL.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .disabled(isLoading || ficURL.trimmingCharacters(in: .whitespaces).isEmpty)
                
                Spacer()
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .navigationDestination(isPresented: $navigateToReader) {
                if let fic = parsedFic {
                    ReaderView(fic: fic)
                }
            }
            .alert("Error Loading Fic", isPresented: $showErrorAlert, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(errorMessage ?? "An unknown error occurred.")
            })
        }
    }
    
    private func loadFic() {
        let cleanURL = ficURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanURL.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fic = try await FicParser.fetchAndParse(urlString: cleanURL)
                await MainActor.run {
                    self.parsedFic = fic
                    self.isLoading = false
                    self.navigateToReader = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    self.showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
