import SwiftUI
import CoreText

extension UIFont {
    func bold() -> UIFont {
        if let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) {
            return UIFont(descriptor: descriptor, size: 0)
        }
        return self
    }
}

struct PageData: Identifiable {
    let id = UUID()
    let paragraphs: [Paragraph]
}

struct ReaderView: View {
    let fic: Fic
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentChapterIndex = 0
    @State private var currentPageIndex = 0
    @State private var showMenuSheet = false
    
    // AttributedString pages calculated by CoreText
    @State private var pages: [PageData] = []
    @State private var containerSize: CGSize = .zero
    
    @AppStorage("readerFontSize") private var fontSize: Double = 16.0
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @ObservedObject private var libraryManager = LibraryManager.shared
    
    // Custom App Skins Storage (Hex Strings)
    @AppStorage("theme_backgroundColorHex") private var backgroundColorHex = "#F5F5F3"
    @AppStorage("theme_textColorHex") private var textColorHex = "#222222"
    @AppStorage("theme_accentColorHex") private var accentColorHex = "#B08F54"
    @AppStorage("theme_fontName") private var fontName = "Georgia"
    
    private var themeBg: Color { Color(hex: backgroundColorHex) }
    private var themeText: Color { Color(hex: textColorHex) }
    private var themeAccent: Color { Color(hex: accentColorHex) }
    
    var currentChapter: Chapter {
        if fic.chapters.indices.contains(currentChapterIndex) {
            return fic.chapters[currentChapterIndex]
        }
        return fic.chapters.first ?? Chapter(title: "Empty", content: [], preNotes: nil, postNotes: nil)
    }
    
    func readerFont(size: CGFloat) -> Font {
        if fontName == "System" {
            return .system(size: size)
        } else {
            return .custom(fontName, size: size)
        }
    }
    
    func getUIFont(size: CGFloat) -> UIFont {
        if fontName == "System" {
            return .systemFont(ofSize: size)
        } else {
            return UIFont(name: fontName, size: size) ?? .systemFont(ofSize: size)
        }
    }
    
    func safeAttributedString(from markdown: String) -> AttributedString {
        do {
            return try AttributedString(markdown: markdown, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            return AttributedString(markdown)
        }
    }
    
    // Calculate the height of a single paragraph in pixels under current font, size, and layout width bounds
    func calculateParagraphHeight(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        guard let attr = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) else {
            let nsAttr = NSAttributedString(
                string: text,
                attributes: [NSAttributedString.Key.font: font]
            )
            let constraint = CGSize(width: width, height: .greatestFiniteMagnitude)
            let rect = nsAttr.boundingRect(with: constraint, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            return ceil(rect.height)
        }
        
        let ns = NSMutableAttributedString(attr)
        let fullRange = NSRange(location: 0, length: ns.length)
        ns.addAttribute(NSAttributedString.Key.font, value: font, range: fullRange)
        
        ns.enumerateAttribute(NSAttributedString.Key.font, in: fullRange, options: []) { value, range, _ in
            if let currentFont = value as? UIFont {
                let descriptor = currentFont.fontDescriptor
                let isBold = descriptor.symbolicTraits.contains(.traitBold)
                let isItalic = descriptor.symbolicTraits.contains(.traitItalic)
                
                var newDescriptor = font.fontDescriptor
                if isBold {
                    newDescriptor = newDescriptor.withSymbolicTraits(newDescriptor.symbolicTraits.union(.traitBold)) ?? newDescriptor
                }
                if isItalic {
                    newDescriptor = newDescriptor.withSymbolicTraits(newDescriptor.symbolicTraits.union(.traitItalic)) ?? newDescriptor
                }
                
                let resolvedFont = UIFont(descriptor: newDescriptor, size: font.pointSize)
                ns.addAttribute(NSAttributedString.Key.font, value: resolvedFont, range: range)
            }
        }
        
        let constraint = CGSize(width: width, height: .greatestFiniteMagnitude)
        let rect = ns.boundingRect(with: constraint, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return ceil(rect.height)
    }
    
    func calculateTextHeight(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let nsAttr = NSAttributedString(
            string: text,
            attributes: [NSAttributedString.Key.font: font]
        )
        let constraint = CGSize(width: width, height: .greatestFiniteMagnitude)
        let rect = nsAttr.boundingRect(with: constraint, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return ceil(rect.height)
    }
    
    // Group paragraphs into pages by measuring their exact heights dynamically
    func repaginate() {
        guard containerSize.width > 0 && containerSize.height > 0 else { return }
        
        let width = containerSize.width - 48
        // Deduct 8 pt of padding to leave a tiny bottom margin
        let maxHeight = containerSize.height - 8
        
        let font = getUIFont(size: CGFloat(fontSize))
        
        let filteredContent = currentChapter.content.filter {
            $0.isHorizontalRule || !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        var allParagraphs: [Paragraph] = []
        if let preNotes = currentChapter.preNotes {
            let filteredPre = preNotes.filter { $0.isHorizontalRule || !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            allParagraphs.append(contentsOf: filteredPre)
        }
        allParagraphs.append(contentsOf: filteredContent)
        if let postNotes = currentChapter.postNotes {
            let filteredPost = postNotes.filter { $0.isHorizontalRule || !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            allParagraphs.append(contentsOf: filteredPost)
        }
        
        var paginatedPages: [PageData] = []
        var currentGroup: [Paragraph] = []
        var currentHeight: CGFloat = 0
        let paragraphSpacing: CGFloat = 16
        
        for paragraph in allParagraphs {
            let pHeight: CGFloat
            if paragraph.isHorizontalRule {
                pHeight = 32 // Height occupied by divider
            } else {
                pHeight = calculateParagraphHeight(text: paragraph.text, font: font, width: width)
            }
            
            // Calculate header overheads on page 0
            var extraHeaderHeight: CGFloat = 0
            if paginatedPages.isEmpty && currentChapterIndex == 0 && currentGroup.isEmpty {
                extraHeaderHeight += calculateTextHeight(text: fic.title, font: getUIFont(size: 28).bold(), width: width) + 8
                extraHeaderHeight += calculateTextHeight(text: "by " + fic.author, font: getUIFont(size: 16), width: width) + 16
                extraHeaderHeight += 32 // divider line area
            }
            if currentGroup.isEmpty && !fic.isSingleChapter {
                extraHeaderHeight += calculateTextHeight(text: currentChapter.title, font: getUIFont(size: 22).bold(), width: width) + 24
            }
            
            let neededHeight = currentHeight == 0 ? (pHeight + extraHeaderHeight) : (pHeight + paragraphSpacing)
            
            // Split page if height limit is reached
            if currentHeight + neededHeight > maxHeight && !currentGroup.isEmpty {
                paginatedPages.append(PageData(paragraphs: currentGroup))
                currentGroup = [paragraph]
                
                // Set initial height for new page (which might have chapter title overhead if first page of a subsequent chapter)
                var nextExtraHeaderHeight: CGFloat = 0
                if !fic.isSingleChapter && paginatedPages.count == 0 { // First page already saved, this branch handles subsequent ones
                    nextExtraHeaderHeight = 0
                }
                currentHeight = pHeight + nextExtraHeaderHeight
            } else {
                currentGroup.append(paragraph)
                currentHeight += neededHeight
            }
        }
        
        if !currentGroup.isEmpty {
            paginatedPages.append(PageData(paragraphs: currentGroup))
        }
        
        self.pages = paginatedPages
        
        if currentPageIndex >= pages.count {
            currentPageIndex = max(0, pages.count - 1)
        }
    }
    
    var body: some View {
        ZStack {
            // Background Canvas color
            themeBg.ignoresSafeArea()
            
            GeometryReader { geo in
                let areaSize = CGSize(
                    width: geo.size.width,
                    height: geo.size.height
                )
                
                Group {
                    if !pages.isEmpty {
                        TabView(selection: $currentPageIndex) {
                            ForEach(0..<pages.count, id: \.self) { index in
                                let page = pages[index]
                                VStack(alignment: .leading, spacing: 0) {
                                    // 1. If page 0 of chapter 0, print work metadata
                                    if index == 0 && currentChapterIndex == 0 {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(fic.title)
                                                .font(readerFont(size: 28).bold())
                                                .foregroundColor(themeText)
                                            Text("by \(fic.author)")
                                                .font(readerFont(size: 16))
                                                .foregroundColor(.secondary)
                                            
                                            HStack {
                                                Spacer()
                                                Text("— — — — —")
                                                    .font(readerFont(size: 14))
                                                    .foregroundColor(themeAccent)
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                    
                                    // 2. If page 0 of any chapter, print chapter title
                                    if index == 0 && !fic.isSingleChapter {
                                        Text(currentChapter.title)
                                            .font(readerFont(size: 22).bold())
                                            .foregroundColor(themeText)
                                            .padding(.bottom, 24)
                                            .padding(.horizontal, 24)
                                    }
                                    
                                    // 3. Render paragraphs using beautiful SwiftUI layouts
                                    VStack(alignment: .leading, spacing: 16) {
                                        ForEach(page.paragraphs) { paragraph in
                                            if paragraph.isHorizontalRule {
                                                HStack {
                                                    Spacer()
                                                    Text("— — — — —")
                                                        .font(readerFont(size: 14))
                                                        .foregroundColor(themeAccent)
                                                    Spacer()
                                                }
                                                .padding(.vertical, 8)
                                            } else {
                                                Text(safeAttributedString(from: paragraph.text))
                                                    .font(readerFont(size: CGFloat(fontSize)))
                                                    .foregroundColor(themeText)
                                                    .frame(maxWidth: .infinity, alignment: paragraph.alignment.frameAlignment)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    
                                    Spacer(minLength: 0)
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .onChange(of: geo.size) { newSize in
                    containerSize = newSize
                    repaginate()
                }
                .onChange(of: fontSize) { _ in
                    repaginate()
                }
                .onChange(of: fontName) { _ in
                    repaginate()
                }
                .onChange(of: currentChapterIndex) { _ in
                    currentPageIndex = 0
                    repaginate()
                }
                .onAppear {
                    containerSize = areaSize
                    repaginate()
                }
            }
        }
        .safeAreaInset(edge: .top) {
            HStack(alignment: .center) {
                Spacer()
                if !pages.isEmpty {
                    Text("\(pages.count - 1 - currentPageIndex) pages left in chapter")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                        .padding(.leading, 32)
                }
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.body.bold())
                        .foregroundColor(themeAccent)
                        .padding(8)
                        .background(Circle().fill(themeAccent.opacity(0.12)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(themeBg.opacity(0.96))
        }
        .safeAreaInset(edge: .bottom) {
            HStack(alignment: .center) {
                Spacer()
                if !pages.isEmpty {
                    Text("\(currentPageIndex + 1) of \(pages.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 32)
                }
                Spacer()
                
                Button(action: {
                    showMenuSheet = true
                }) {
                    Image(systemName: "list.bullet")
                        .font(.body.bold())
                        .foregroundColor(themeAccent)
                        .padding(8)
                        .background(Circle().fill(themeAccent.opacity(0.12)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(themeBg.opacity(0.96))
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $showMenuSheet) {
            NavigationStack {
                List {
                    Section(header: Text("Table of Contents")) {
                        ForEach(0..<fic.chapters.count, id: \.self) { index in
                            Button(action: {
                                currentChapterIndex = index
                                currentPageIndex = 0
                                showMenuSheet = false
                            }) {
                                HStack {
                                    Text(fic.chapters[index].title)
                                        .foregroundColor(index == currentChapterIndex ? themeAccent : .primary)
                                        .font(.system(size: 16))
                                    Spacer()
                                    if index == currentChapterIndex {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(themeAccent)
                                    }
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Offline Bookmark")) {
                        Button(action: {
                            if libraryManager.isSaved(fic.id) {
                                libraryManager.deleteFic(fic)
                            } else {
                                libraryManager.saveFic(fic)
                            }
                        }) {
                            HStack {
                                Label(libraryManager.isSaved(fic.id) ? "Saved Offline" : "Save for Offline Reading",
                                      systemImage: libraryManager.isSaved(fic.id) ? "bookmark.fill" : "bookmark")
                                    .foregroundColor(themeAccent)
                                    .font(.system(size: 16))
                                Spacer()
                            }
                        }
                    }
                    
                    Section(header: Text("Quick Font Sizing")) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Font Size")
                                Spacer()
                                Text("\(Int(fontSize)) pt")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $fontSize, in: 12...28, step: 1)
                                .tint(themeAccent)
                        }
                    }
                }
                .navigationTitle("Reader Options")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showMenuSheet = false
                        }
                        .foregroundColor(themeAccent)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}
