import Foundation

struct SearchResult: Identifiable, Hashable, Codable {
    let id: String // AO3 Work ID
    let title: String
    let author: String
    let fandoms: [String]
    let summary: String
    let tags: [String]
    let language: String
    let wordCount: String
    let chapterInfo: String // e.g. "1/1" or "3/5"
    let kudos: String
    let hits: String
}
