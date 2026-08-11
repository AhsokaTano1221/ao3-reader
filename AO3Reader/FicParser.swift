import Foundation
import SwiftSoup

enum ParserError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case emptyResponse
    case parsingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided is not a valid AO3 work URL."
        case .networkError(let error):
            return "Failed to connect to AO3: \(error.localizedDescription)"
        case .emptyResponse:
            return "No content returned from AO3. Make sure the URL is correct."
        case .parsingFailed(let reason):
            return "Failed to extract story text: \(reason)"
        }
    }
}

struct FicParser {
    
    static func extractWorkID(from urlString: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "works/([0-9]+)", options: .caseInsensitive) else {
            return nil
        }
        let nsString = urlString as NSString
        let results = regex.matches(in: urlString, options: [], range: NSRange(location: 0, length: nsString.length))
        guard let match = results.first, match.numberOfRanges > 1 else {
            return nil
        }
        return nsString.substring(with: match.range(at: 1))
    }
    
    static func htmlToMarkdown(_ html: String) throws -> String {
        var markdown = html
        
        // 1. Replace breaks with newlines (using double spaces for hard breaks in Markdown)
        markdown = markdown.replacingOccurrences(of: "<br\\s*/?>", with: "  \n", options: .regularExpression, range: nil)
        
        // 2. Replace strong/bold tags
        markdown = markdown.replacingOccurrences(of: "<strong\\s*>", with: "**", options: .regularExpression, range: nil)
        markdown = markdown.replacingOccurrences(of: "</strong>", with: "**", range: nil)
        markdown = markdown.replacingOccurrences(of: "<b\\s*>", with: "**", options: .regularExpression, range: nil)
        markdown = markdown.replacingOccurrences(of: "</b>", with: "**", range: nil)
        
        // 3. Replace em/italic tags
        markdown = markdown.replacingOccurrences(of: "<em\\s*>", with: "*", options: .regularExpression, range: nil)
        markdown = markdown.replacingOccurrences(of: "</em>", with: "*", range: nil)
        markdown = markdown.replacingOccurrences(of: "<i\\s*>", with: "*", options: .regularExpression, range: nil)
        markdown = markdown.replacingOccurrences(of: "</i>", with: "*", range: nil)
        
        // 4. Strip any other HTML tags to prevent raw HTML display
        markdown = markdown.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        
        // 5. Decode HTML entities
        return try Entities.unescape(markdown)
    }
    
    static func parseAlignment(from element: Element) -> FicTextAlignment {
        // Check "align" attribute
        if let alignAttr = try? element.attr("align").lowercased(), !alignAttr.isEmpty {
            if alignAttr == "center" { return .center }
            if alignAttr == "right" { return .trailing }
            if alignAttr == "left" { return .leading }
        }
        
        // Check "style" attribute
        if let styleAttr = try? element.attr("style").lowercased(), !styleAttr.isEmpty {
            if styleAttr.contains("text-align: center") || styleAttr.contains("text-align:center") {
                return .center
            }
            if styleAttr.contains("text-align: right") || styleAttr.contains("text-align:right") {
                return .trailing
            }
            if styleAttr.contains("text-align: left") || styleAttr.contains("text-align:left") {
                return .leading
            }
        }
        
        // Check class names
        if let className = try? element.className().lowercased() {
            if className.contains("center") { return .center }
            if className.contains("right") { return .trailing }
        }
        
        return .leading
    }
    
    static func parseNotes(from container: Element?) throws -> [Paragraph]? {
        guard let container = container else { return nil }
        
        // Inside a notes module, the actual note content is usually inside a blockquote with class "userstuff"
        let userstuff = try container.select("blockquote.userstuff").first() ?? container
        
        let storyElements = try userstuff.select("p, hr")
        if !storyElements.isEmpty() {
            let paragraphs = try storyElements.map { elem in
                if elem.tagName() == "hr" {
                    return Paragraph(text: "", alignment: .center, isHorizontalRule: true)
                } else {
                    let markdown = try htmlToMarkdown(elem.html()).trimmingCharacters(in: .newlines)
                    let alignment = parseAlignment(from: elem)
                    return Paragraph(text: markdown, alignment: alignment, isHorizontalRule: false)
                }
            }.filter { $0.isHorizontalRule || !$0.text.isEmpty }
            return paragraphs.isEmpty ? nil : paragraphs
        } else {
            let htmlStr = try userstuff.html()
            let markdown = try htmlToMarkdown(htmlStr)
            let paragraphs = markdown.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .newlines) }
                .filter { !$0.isEmpty }
                .map { Paragraph(text: $0, alignment: .leading) }
            return paragraphs.isEmpty ? nil : paragraphs
        }
    }
    
    static func fetchAndParse(urlString: String) async throws -> Fic {
        guard let workID = extractWorkID(from: urlString) else {
            throw ParserError.invalidURL
        }
        
        let cleanURLString = "https://archiveofourown.org/works/\(workID)?view_adult=true&view_full_work=true"
        guard let url = URL(string: cleanURLString) else {
            throw ParserError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ParserError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ParserError.emptyResponse
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw ParserError.parsingFailed("Unable to decode content.")
        }
        
        do {
            let doc: Document = try SwiftSoup.parse(html)
            
            // 1. Parse Title
            guard let titleElement = try doc.select("h2.title.heading").first() else {
                throw ParserError.parsingFailed("Story title not found.")
            }
            let title = try titleElement.text().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 2. Parse Author
            var author = "Anonymous"
            if let authorElement = try doc.select("h3.byline.heading a[rel=author]").first() {
                author = try authorElement.text().trimmingCharacters(in: .whitespacesAndNewlines)
            } else if let authorElement = try doc.select("h3.byline.heading").first() {
                author = try authorElement.text().trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Parse work preface/notes (global)
            let workPreNotesElem = try doc.select("#workskin div.preface div.notes:not(.end)").first()
            let workPreNotes = try parseNotes(from: workPreNotesElem)
            
            let workPostNotesElem = try doc.select("#workskin div.preface div.end.notes").first()
                ?? doc.select("div#feedback div.end.notes").first()
            let workPostNotes = try parseNotes(from: workPostNotesElem)
            
            // 3. Parse Chapters
            var chapters: [Chapter] = []
            
            // Check for multi-chapter containers
            let chapterElements = try doc.select("div#chapters > div.chapter")
            
            if !chapterElements.isEmpty() {
                // Multi-chapter work
                for (index, chElem) in chapterElements.enumerated() {
                    // Extract title
                    var chTitle = "Chapter \(index + 1)"
                    if let titleElem = try chElem.select("h3.title").first() {
                        chTitle = try titleElem.text().trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    
                    // Extract body (selecting both p and hr tags)
                    let bodyElement = try chElem.select("div.userstuff[role=article]").first() ?? chElem.select("div.userstuff").first()
                    var paragraphs: [Paragraph] = []
                    
                    if let bodyElement = bodyElement {
                        let storyElements = try bodyElement.select("p, hr")
                        if !storyElements.isEmpty() {
                            paragraphs = try storyElements.map { elem in
                                if elem.tagName() == "hr" {
                                    return Paragraph(text: "", alignment: .center, isHorizontalRule: true)
                                } else {
                                    let markdown = try htmlToMarkdown(elem.html()).trimmingCharacters(in: .newlines)
                                    let alignment = parseAlignment(from: elem)
                                    return Paragraph(text: markdown, alignment: alignment, isHorizontalRule: false)
                                }
                            }.filter { $0.isHorizontalRule || !$0.text.isEmpty }
                        } else {
                            let markdown = try htmlToMarkdown(bodyElement.html())
                            paragraphs = markdown.components(separatedBy: "\n")
                                .map { $0.trimmingCharacters(in: .newlines) }
                                .filter { !$0.isEmpty }
                                .map { Paragraph(text: $0, alignment: .leading) }
                        }
                    }
                    
                    // Extract chapter notes
                    let preNotesElem = try chElem.select("div.notes:not(.end)").first()
                    var preNotes = try parseNotes(from: preNotesElem)
                    
                    let postNotesElem = try chElem.select("div.end.notes").first()
                    var postNotes = try parseNotes(from: postNotesElem)
                    
                    // If it is the first chapter, prepend global work preface notes
                    if index == 0, let workPre = workPreNotes {
                        preNotes = workPre + (preNotes ?? [])
                    }
                    
                    // If it is the last chapter, append global work end notes
                    if index == chapterElements.count - 1, let workPost = workPostNotes {
                        postNotes = (postNotes ?? []) + workPost
                    }
                    
                    chapters.append(Chapter(title: chTitle, content: paragraphs, preNotes: preNotes, postNotes: postNotes))
                }
            } else {
                // Single-chapter work
                let bodyElement = try doc.select("div#workskin div.userstuff[role=article]").first() ?? doc.select("div#workskin div.userstuff").first() ?? doc.select("div.userstuff").first()
                var paragraphs: [Paragraph] = []
                
                if let bodyElement = bodyElement {
                    let storyElements = try bodyElement.select("p, hr")
                    if !storyElements.isEmpty() {
                        paragraphs = try storyElements.map { elem in
                            if elem.tagName() == "hr" {
                                return Paragraph(text: "", alignment: .center, isHorizontalRule: true)
                            } else {
                                let markdown = try htmlToMarkdown(elem.html()).trimmingCharacters(in: .newlines)
                                let alignment = parseAlignment(from: elem)
                                return Paragraph(text: markdown, alignment: alignment, isHorizontalRule: false)
                            }
                        }.filter { $0.isHorizontalRule || !$0.text.isEmpty }
                    } else {
                        let markdown = try htmlToMarkdown(bodyElement.html())
                        paragraphs = markdown.components(separatedBy: "\n")
                            .map { $0.trimmingCharacters(in: .newlines) }
                            .filter { !$0.isEmpty }
                            .map { Paragraph(text: $0, alignment: .leading) }
                    }
                }
                
                chapters.append(Chapter(title: title, content: paragraphs, preNotes: workPreNotes, postNotes: workPostNotes))
            }
            
            if chapters.isEmpty || (chapters.count == 1 && chapters[0].content.isEmpty) {
                throw ParserError.parsingFailed("No readable content found. The work might be restricted or deleted.")
            }
            
            return Fic(id: workID, title: title, author: author, chapters: chapters, url: urlString)
            
        } catch let error as ParserError {
            throw error
        } catch {
            throw ParserError.parsingFailed(error.localizedDescription)
        }
    }
}
