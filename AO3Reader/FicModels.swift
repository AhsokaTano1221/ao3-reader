import Foundation
import SwiftUI

enum FicTextAlignment: String, Codable {
    case leading
    case center
    case trailing
    
    var toSwiftUI: TextAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
    
    var frameAlignment: Alignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

struct Paragraph: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    let text: String // Markdown string
    let alignment: FicTextAlignment
    var isHorizontalRule: Bool = false
}

struct Chapter: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    let title: String
    let content: [Paragraph] // Array of parsed paragraphs
    let preNotes: [Paragraph]? // Notes at the beginning of the chapter/work
    let postNotes: [Paragraph]? // Notes at the end of the chapter/work
}

struct Fic: Identifiable, Hashable, Codable {
    let id: String // AO3 Work ID
    let title: String
    let author: String
    let chapters: [Chapter]
    let url: String
    
    var isSingleChapter: Bool {
        chapters.count <= 1
    }
}
