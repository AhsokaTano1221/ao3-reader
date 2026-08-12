import Foundation

class LibraryManager: ObservableObject {
    static let shared = LibraryManager()
    
    @Published var savedFics: [Fic] = []
    
    private let fileManager = FileManager.default
    
    private var libraryDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let libraryPath = paths[0].appendingPathComponent("Library", isDirectory: true)
        if !fileManager.fileExists(atPath: libraryPath.path) {
            try? fileManager.createDirectory(at: libraryPath, withIntermediateDirectories: true, attributes: nil)
        }
        return libraryPath
    }
    
    private init() {
        loadLibrary()
    }
    
    func loadLibrary() {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: libraryDirectory, includingPropertiesForKeys: nil)
            let jsonURLs = fileURLs.filter { $0.pathExtension == "json" }
            
            var loadedFics: [Fic] = []
            let decoder = JSONDecoder()
            
            for url in jsonURLs {
                if let data = try? Data(contentsOf: url),
                   let fic = try? decoder.decode(Fic.self, from: data) {
                    loadedFics.append(fic)
                }
            }
            
            DispatchQueue.main.async {
                self.savedFics = loadedFics.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            }
        } catch {
            print("Failed to load library: \(error)")
        }
    }
    
    func isSaved(_ workID: String) -> Bool {
        savedFics.contains(where: { $0.id == workID })
    }
    
    func saveFic(_ fic: Fic) {
        let fileURL = libraryDirectory.appendingPathComponent("\(fic.id).json")
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(fic)
            try data.write(to: fileURL, options: .atomic)
            loadLibrary()
        } catch {
            print("Failed to save fic: \(error)")
        }
    }
    
    func deleteFic(_ fic: Fic) {
        let fileURL = libraryDirectory.appendingPathComponent("\(fic.id).json")
        try? fileManager.removeItem(at: fileURL)
        loadLibrary()
    }
}
