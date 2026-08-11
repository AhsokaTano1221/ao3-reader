import SwiftUI

struct ReaderView: View {
    let fic: Fic
    
    @State private var currentChapterIndex = 0
    @AppStorage("readerFontSize") private var fontSize: Double = 16.0
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var currentChapter: Chapter {
        if fic.chapters.indices.contains(currentChapterIndex) {
            return fic.chapters[currentChapterIndex]
        }
        return fic.chapters.first ?? Chapter(title: "Empty", content: [], preNotes: nil, postNotes: nil)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chapter Selection Header (only if multi-chapter)
            if fic.chapters.count > 1 {
                HStack {
                    Button(action: {
                        if currentChapterIndex > 0 {
                            currentChapterIndex -= 1
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .padding()
                    }
                    .disabled(currentChapterIndex == 0)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(0..<fic.chapters.count, id: \.self) { index in
                            Button(action: {
                                currentChapterIndex = index
                            }) {
                                HStack {
                                    Text(fic.chapters[index].title)
                                    if index == currentChapterIndex {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(currentChapter.title)
                                .font(.headline)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.subheadline)
                        }
                        .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if currentChapterIndex < fic.chapters.count - 1 {
                            currentChapterIndex += 1
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .padding()
                    }
                    .disabled(currentChapterIndex == fic.chapters.count - 1)
                }
                .padding(.horizontal)
                .background(Color(.secondarySystemBackground))
            }
            
            // Text Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header inside scroll view
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fic.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("by \(fic.author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if !fic.isSingleChapter {
                            Text(currentChapter.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Beginning notes (if any)
                    if let preNotes = currentChapter.preNotes {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "note.text")
                                Text("Chapter Notes")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            ForEach(preNotes) { paragraph in
                                if paragraph.isHorizontalRule {
                                    Divider()
                                        .padding(.vertical, 4)
                                } else {
                                    Text(formattedParagraph(paragraph.text))
                                        .font(.system(size: CGFloat(max(12, fontSize - 2))))
                                        .lineSpacing(4)
                                        .multilineTextAlignment(paragraph.alignment.toSwiftUI)
                                        .frame(maxWidth: .infinity, alignment: paragraph.alignment.frameAlignment)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.bottom, 8)
                    }
                    
                    // Main body paragraphs
                    ForEach(currentChapter.content) { paragraph in
                        if paragraph.isHorizontalRule {
                            Divider()
                                .frame(width: 100)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text(formattedParagraph(paragraph.text))
                                .font(.system(size: CGFloat(fontSize)))
                                .lineSpacing(6)
                                .multilineTextAlignment(paragraph.alignment.toSwiftUI)
                                .frame(maxWidth: .infinity, alignment: paragraph.alignment.frameAlignment)
                        }
                    }
                    
                    // Ending notes (if any)
                    if let postNotes = currentChapter.postNotes {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "note.text")
                                Text("Notes at the End")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            ForEach(postNotes) { paragraph in
                                if paragraph.isHorizontalRule {
                                    Divider()
                                        .padding(.vertical, 4)
                                } else {
                                    Text(formattedParagraph(paragraph.text))
                                        .font(.system(size: CGFloat(max(12, fontSize - 2))))
                                        .lineSpacing(4)
                                        .multilineTextAlignment(paragraph.alignment.toSwiftUI)
                                        .frame(maxWidth: .infinity, alignment: paragraph.alignment.frameAlignment)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.top, 16)
                    }
                    
                    // Multi-chapter navigation footer
                    if fic.chapters.count > 1 {
                        Divider()
                            .padding(.top, 20)
                        
                        HStack {
                            if currentChapterIndex > 0 {
                                Button("Previous Chapter") {
                                    currentChapterIndex -= 1
                                }
                            }
                            
                            Spacer()
                            
                            if currentChapterIndex < fic.chapters.count - 1 {
                                Button("Next Chapter") {
                                    currentChapterIndex += 1
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(fic.isSingleChapter ? "Reading" : "Chapter \(currentChapterIndex + 1)")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    private func formattedParagraph(_ markdown: String) -> AttributedString {
        do {
            return try AttributedString(
                markdown: markdown,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            )
        } catch {
            return AttributedString(markdown) // Fallback to plain text
        }
    }
}

#Preview {
    NavigationStack {
        ReaderView(fic: Fic(
            id: "12345",
            title: "Test Fanfiction",
            author: "Author Name",
            chapters: [
                Chapter(title: "Chapter 1: The Beginning", content: [
                    Paragraph(text: "Paragraph 1 of **bold** and *italic* story.", alignment: .leading),
                    Paragraph(text: "", alignment: .center, isHorizontalRule: true),
                    Paragraph(text: "Paragraph 2 with a \nnewline break.", alignment: .leading)
                ], preNotes: [
                    Paragraph(text: "These are starting author notes for the chapter.", alignment: .leading)
                ], postNotes: [
                    Paragraph(text: "These are ending author notes for the chapter.", alignment: .leading)
                ]),
                Chapter(title: "Chapter 2: The End", content: [
                    Paragraph(text: "This is the second chapter paragraph.", alignment: .center)
                ], preNotes: nil, postNotes: nil)
            ],
            url: "https://archiveofourown.org/works/12345"
        ))
    }
}
