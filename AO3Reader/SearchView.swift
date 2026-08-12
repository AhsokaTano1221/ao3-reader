import SwiftUI

struct SearchView: View {
    // Work Info States
    @State private var query = ""
    @State private var title = ""
    @State private var creator = ""
    @State private var date = ""
    @State private var completionStatus = "all" // "all", "complete", "in_progress"
    @State private var crossoverStatus = "include" // "include", "exclude", "only"
    @State private var isSingleChapter = false
    @State private var wordCount = ""
    @State private var language = ""
    
    // Work Tags States
    @State private var fandoms = ""
    @State private var rating = ""
    @State private var selectedWarnings: Set<String> = []
    @State private var selectedCategories: Set<String> = []
    @State private var characters = ""
    @State private var relationships = ""
    @State private var additionalTags = ""
    
    // Work Stats States
    @State private var hits = ""
    @State private var kudos = ""
    @State private var comments = ""
    @State private var bookmarks = ""
    
    // Search Options
    @State private var sortBy = "_score" // Relevance
    @State private var sortDirection = "desc" // Descending
    
    // Search Execution States
    @State private var results: [SearchResult] = []
    @State private var isSearching = false
    @State private var searchError: String?
    
    @State private var loadedFic: Fic?
    @State private var isLoadingFic = false
    @State private var loadFicError: String?
    @State private var showReader = false
    
    // Search Mode States
    @State private var searchMode = 0 // 0 = AO3 Search, 1 = Direct URL
    @State private var directURL = ""
    
    // Pagination States
    @State private var currentPage = 1
    @State private var canLoadMore = true
    @State private var isLoadingMore = false
    
    // Autocomplete Suggestions States
    @State private var suggestions: [String] = []
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case query, title, creator, date, wordCount
        case fandoms, characters, relationships, additionalTags
        case hits, kudos, comments, bookmarks
        case directURL
    }
    
    // Option Arrays
    let ratingOptions = [
        RatingOption(id: "", label: "All Ratings"),
        RatingOption(id: "9", label: "Not Rated"),
        RatingOption(id: "10", label: "General Audiences"),
        RatingOption(id: "11", label: "Teen and Up Audiences"),
        RatingOption(id: "12", label: "Mature"),
        RatingOption(id: "13", label: "Explicit")
    ]
    
    let languageOptions = [
        LanguageOption(id: "", label: "All Languages"),
        LanguageOption(id: "en", label: "English"),
        LanguageOption(id: "es", label: "Spanish"),
        LanguageOption(id: "fr", label: "French"),
        LanguageOption(id: "de", label: "German"),
        LanguageOption(id: "zh", label: "Chinese"),
        LanguageOption(id: "ru", label: "Russian"),
        LanguageOption(id: "ja", label: "Japanese"),
        LanguageOption(id: "pt", label: "Portuguese"),
        LanguageOption(id: "it", label: "Italian")
    ]
    
    let warningOptions = [
        WarningSelection(id: "14", label: "Creator Chose Not To Use Archive Warnings"),
        WarningSelection(id: "17", label: "Graphic Depictions Of Violence"),
        WarningSelection(id: "18", label: "Major Character Death"),
        WarningSelection(id: "16", label: "No Archive Warnings Apply"),
        WarningSelection(id: "19", label: "Rape/Non-Con"),
        WarningSelection(id: "20", label: "Underage Sex")
    ]
    
    let categoryOptions = [
        CategorySelection(id: "116", label: "F/F"),
        CategorySelection(id: "22", label: "F/M"),
        CategorySelection(id: "21", label: "Gen"),
        CategorySelection(id: "23", label: "M/M"),
        CategorySelection(id: "224", label: "Multi"),
        CategorySelection(id: "24", label: "Other")
    ]
    
    let sortOptions = [
        SortOption(id: "_score", label: "Relevance"),
        SortOption(id: "kudos_count", label: "Kudos"),
        SortOption(id: "hits", label: "Hits"),
        SortOption(id: "bookmarks_count", label: "Bookmarks"),
        SortOption(id: "comments_count", label: "Comments"),
        SortOption(id: "revised_at", label: "Date Updated"),
        SortOption(id: "created_at", label: "Date Created"),
        SortOption(id: "word_count", label: "Word Count"),
        SortOption(id: "authors_to_sort_on", label: "Author"),
        SortOption(id: "title_to_sort_on", label: "Title")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Search Mode", selection: $searchMode) {
                    Text("AO3 Search").tag(0)
                    Text("Direct URL").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                ZStack {
                    if searchMode == 0 {
                        Form {
                            workInfoSection
                            workTagsSection
                            workStatsSection
                            sortSection
                            
                            // Search Button Section
                            Section {
                                Button(action: performSearch) {
                                    HStack {
                                        Spacer()
                                        if isSearching {
                                            ProgressView()
                                                .padding(.trailing, 8)
                                        }
                                        Text(isSearching ? "Searching..." : "Search AO3")
                                            .fontWeight(.semibold)
                                        Spacer()
                                    }
                                }
                                .disabled(isSearching || (query.isEmpty && title.isEmpty && creator.isEmpty && fandoms.isEmpty && characters.isEmpty && relationships.isEmpty && additionalTags.isEmpty))
                            }
                            
                            // Search Results Section
                            if !results.isEmpty {
                                Section(header: Text("Search Results (\(results.count))")) {
                                    ForEach(results) { result in
                                        SearchResultCard(result: result) {
                                            loadFic(id: result.id)
                                        }
                                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                        .listRowSeparator(.hidden)
                                    }
                                    
                                    if canLoadMore {
                                        Button(action: loadNextPage) {
                                            HStack {
                                                Spacer()
                                                if isLoadingMore {
                                                    ProgressView()
                                                        .padding(.trailing, 8)
                                                }
                                                Text(isLoadingMore ? "Loading more..." : "Load More")
                                                    .fontWeight(.medium)
                                                Spacer()
                                            }
                                        }
                                        .disabled(isLoadingMore)
                                        .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                                    }
                                }
                            }
                        }
                    } else {
                        Form {
                            Section(header: Text("Load via Direct URL")) {
                                TextField("https://archiveofourown.org/works/...", text: $directURL)
                                    .keyboardType(.URL)
                                    .autocorrectionDisabled(true)
                                    .textInputAutocapitalization(.never)
                                    .focused($focusedField, equals: .directURL)
                                
                                Button(action: {
                                    loadFic(urlString: directURL)
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("Load Fic")
                                            .fontWeight(.semibold)
                                        Spacer()
                                    }
                                }
                                .disabled(directURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                    }
                    
                    // Loading Overlay when downloading a fic
                    if isLoadingFic {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Downloading Fic...")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(Color(.secondarySystemBackground).opacity(0.85))
                        .cornerRadius(16)
                        .shadow(radius: 10)
                    }
                }
            }
            .navigationTitle(searchMode == 0 ? "Search" : "Direct URL")
            .navigationDestination(isPresented: $showReader) {
                if let fic = loadedFic {
                    ReaderView(fic: fic)
                }
            }
            .alert("Search Error", isPresented: Binding(
                get: { searchError != nil },
                set: { if !$0 { searchError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(searchError ?? "")
            }
            .alert("Download Error", isPresented: Binding(
                get: { loadFicError != nil },
                set: { if !$0 { loadFicError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(loadFicError ?? "")
            }
            .onDisappear {
                // Clear search results & pagination states
                self.results = []
                self.currentPage = 1
                self.canLoadMore = true
                self.searchError = nil
                
                // Clear input text fields & tags
                self.query = ""
                self.title = ""
                self.creator = ""
                self.date = ""
                self.wordCount = ""
                self.fandoms = ""
                self.characters = ""
                self.relationships = ""
                self.additionalTags = ""
                self.hits = ""
                self.kudos = ""
                self.comments = ""
                self.bookmarks = ""
                self.directURL = ""
                
                // Reset select controls & collections
                self.completionStatus = "all"
                self.crossoverStatus = "include"
                self.isSingleChapter = false
                self.language = ""
                self.rating = ""
                self.selectedWarnings = []
                self.selectedCategories = []
                
                // Reset sorting options
                self.sortBy = "_score"
                self.sortDirection = "desc"
            }
        }
    }
    
    // View decompositions to optimize compiler type-checking speed
    private var workInfoSection: some View {
        Section(header: Text("Work Info")) {
            TextField("Any Field / Keywords", text: $query)
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .query)
            TextField("Title", text: $title)
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .title)
            TextField("Creator / Author", text: $creator)
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .creator)
            TextField("Date (e.g. \"within 24 hours\")", text: $date)
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .date)
            
            Picker("Completion Status", selection: $completionStatus) {
                Text("All works").tag("all")
                Text("Complete works only").tag("complete")
                Text("Works in progress only").tag("in_progress")
            }
            
            Picker("Crossovers", selection: $crossoverStatus) {
                Text("Include crossovers").tag("include")
                Text("Exclude crossovers").tag("exclude")
                Text("Only crossovers").tag("only")
            }
            
            Toggle("Single Chapter", isOn: $isSingleChapter)
            
            TextField("Word Count (e.g. \">1000\", \"1000-5000\")", text: $wordCount)
                .textInputAutocapitalization(.never)
                .keyboardType(.numbersAndPunctuation)
                .focused($focusedField, equals: .wordCount)
            
            Picker("Language", selection: $language) {
                ForEach(languageOptions, id: \.id) { opt in
                    Text(opt.label).tag(opt.id)
                }
            }
        }
    }
    
    private var workTagsSection: some View {
        Section(header: Text("Work Tags")) {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Fandoms", text: $fandoms)
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .fandoms)
                    .onChange(of: fandoms) { newValue in
                        handleTagChange(newValue, type: "fandom")
                    }
                
                if focusedField == .fandoms && !suggestions.isEmpty {
                    suggestionRow(for: $fandoms)
                }
            }
            
            Picker("Rating", selection: $rating) {
                ForEach(ratingOptions, id: \.id) { opt in
                    Text(opt.label).tag(opt.id)
                }
            }
            
            DisclosureGroup("Archive Warnings") {
                ForEach(warningOptions) { opt in
                    Toggle(opt.label, isOn: Binding(
                        get: { selectedWarnings.contains(opt.id) },
                        set: { isSelected in
                            if isSelected {
                                selectedWarnings.insert(opt.id)
                            } else {
                                selectedWarnings.remove(opt.id)
                            }
                        }
                    ))
                    .font(.subheadline)
                }
            }
            
            DisclosureGroup("Categories") {
                ForEach(categoryOptions) { opt in
                    Toggle(opt.label, isOn: Binding(
                        get: { selectedCategories.contains(opt.id) },
                        set: { isSelected in
                            if isSelected {
                                selectedCategories.insert(opt.id)
                            } else {
                                selectedCategories.remove(opt.id)
                            }
                        }
                    ))
                    .font(.subheadline)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                TextField("Characters", text: $characters)
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .characters)
                    .onChange(of: characters) { newValue in
                        handleTagChange(newValue, type: "character")
                    }
                
                if focusedField == .characters && !suggestions.isEmpty {
                    suggestionRow(for: $characters)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                TextField("Relationships", text: $relationships)
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .relationships)
                    .onChange(of: relationships) { newValue in
                        handleTagChange(newValue, type: "relationship")
                    }
                
                if focusedField == .relationships && !suggestions.isEmpty {
                    suggestionRow(for: $relationships)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                TextField("Additional Tags", text: $additionalTags)
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .additionalTags)
                    .onChange(of: additionalTags) { newValue in
                        handleTagChange(newValue, type: "freeform")
                    }
                
                if focusedField == .additionalTags && !suggestions.isEmpty {
                    suggestionRow(for: $additionalTags)
                }
            }
        }
    }
    
    private var workStatsSection: some View {
        Section(header: Text("Work Stats")) {
            TextField("Hits (e.g. \">100\")", text: $hits)
                .keyboardType(.numbersAndPunctuation)
                .focused($focusedField, equals: .hits)
            TextField("Kudos (e.g. \">50\")", text: $kudos)
                .keyboardType(.numbersAndPunctuation)
                .focused($focusedField, equals: .kudos)
            TextField("Comments (e.g. \">10\")", text: $comments)
                .keyboardType(.numbersAndPunctuation)
                .focused($focusedField, equals: .comments)
            TextField("Bookmarks (e.g. \">5\")", text: $bookmarks)
                .keyboardType(.numbersAndPunctuation)
                .focused($focusedField, equals: .bookmarks)
        }
    }
    
    private var sortSection: some View {
        Section(header: Text("Search Sort & Direction")) {
            Picker("Sort By", selection: $sortBy) {
                ForEach(sortOptions) { option in
                    Text(option.label).tag(option.id)
                }
            }
            
            Picker("Sort Direction", selection: $sortDirection) {
                Text("Descending").tag("desc")
                Text("Ascending").tag("asc")
            }
        }
    }
    
    private func handleTagChange(_ text: String, type: String) {
        let components = text.components(separatedBy: ",")
        let currentTerm = components.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        guard currentTerm.count >= 2 else {
            self.suggestions = []
            return
        }
        
        Task {
            do {
                let list = try await FicParser.fetchAutocompleteSuggestions(term: currentTerm, type: type)
                await MainActor.run {
                    // Make sure we only show suggestions if the field is still focused
                    self.suggestions = list
                }
            } catch {
                await MainActor.run {
                    self.suggestions = []
                }
            }
        }
    }
    
    private func suggestionRow(for textBinding: Binding<String>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        let components = textBinding.wrappedValue.components(separatedBy: ",")
                        var tagList = components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        if !tagList.isEmpty {
                            tagList.removeLast()
                        }
                        tagList.append(suggestion)
                        let joined = tagList.joined(separator: ", ")
                        textBinding.wrappedValue = joined.isEmpty ? "" : joined + ", "
                        self.suggestions = []
                    }) {
                        Text(suggestion)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.12))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func performSearch() {
        isSearching = true
        searchError = nil
        currentPage = 1
        canLoadMore = true
        
        Task {
            do {
                let searchResults = try await FicParser.searchFics(
                    query: query,
                    title: title,
                    author: creator,
                    date: date,
                    completionStatus: completionStatus,
                    crossoverStatus: crossoverStatus,
                    isSingleChapter: isSingleChapter,
                    wordCount: wordCount,
                    language: language,
                    fandoms: fandoms,
                    rating: rating,
                    warnings: selectedWarnings,
                    categories: selectedCategories,
                    characters: characters,
                    relationships: relationships,
                    additionalTags: additionalTags,
                    hits: hits,
                    kudos: kudos,
                    comments: comments,
                    bookmarks: bookmarks,
                    sortBy: sortBy,
                    sortDirection: sortDirection,
                    page: 1
                )
                await MainActor.run {
                    self.results = searchResults
                    self.isSearching = false
                    if searchResults.isEmpty {
                        self.searchError = "No works matching these criteria were found on AO3."
                    }
                    if searchResults.count < 20 {
                        self.canLoadMore = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.searchError = error.localizedDescription
                    self.isSearching = false
                }
            }
        }
    }
    
    private func loadNextPage() {
        guard !isLoadingMore && canLoadMore else { return }
        isLoadingMore = true
        
        Task {
            do {
                let nextPage = currentPage + 1
                let nextResults = try await FicParser.searchFics(
                    query: query,
                    title: title,
                    author: creator,
                    date: date,
                    completionStatus: completionStatus,
                    crossoverStatus: crossoverStatus,
                    isSingleChapter: isSingleChapter,
                    wordCount: wordCount,
                    language: language,
                    fandoms: fandoms,
                    rating: rating,
                    warnings: selectedWarnings,
                    categories: selectedCategories,
                    characters: characters,
                    relationships: relationships,
                    additionalTags: additionalTags,
                    hits: hits,
                    kudos: kudos,
                    comments: comments,
                    bookmarks: bookmarks,
                    sortBy: sortBy,
                    sortDirection: sortDirection,
                    page: nextPage
                )
                
                await MainActor.run {
                    if nextResults.isEmpty {
                        self.canLoadMore = false
                    } else {
                        self.results.append(contentsOf: nextResults)
                        self.currentPage = nextPage
                        if nextResults.count < 20 {
                            self.canLoadMore = false
                        }
                    }
                    self.isLoadingMore = false
                }
            } catch {
                await MainActor.run {
                    self.searchError = error.localizedDescription
                    self.isLoadingMore = false
                }
            }
        }
    }
    
    private func loadFic(id: String) {
        let url = "https://archiveofourown.org/works/\(id)"
        loadFic(urlString: url)
    }
    
    private func loadFic(urlString: String) {
        let cleanURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanURL.isEmpty else { return }
        
        isLoadingFic = true
        loadFicError = nil
        
        Task {
            do {
                let fic = try await FicParser.fetchAndParse(urlString: cleanURL)
                await MainActor.run {
                    self.loadedFic = fic
                    self.isLoadingFic = false
                    self.showReader = true
                }
            } catch {
                await MainActor.run {
                    self.loadFicError = error.localizedDescription
                    self.isLoadingFic = false
                }
            }
        }
    }
}

struct RatingOption {
    let id: String
    let label: String
}

struct LanguageOption {
    let id: String
    let label: String
}

struct WarningSelection: Identifiable {
    let id: String
    let label: String
}

struct CategorySelection: Identifiable {
    let id: String
    let label: String
}

struct SortOption: Identifiable {
    let id: String
    let label: String
}

struct SearchResultCard: View {
    let result: SearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text("by \(result.author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                
                // Fandom Labels
                if !result.fandoms.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(result.fandoms, id: \.self) { fandom in
                                Text(fandom)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                
                // Tags Cloud
                if !result.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(result.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.gray.opacity(0.08))
                                    .foregroundColor(.secondary)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                // Summary snippet
                if !result.summary.isEmpty {
                    Text(result.summary)
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.85))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 2)
                }
                
                Divider()
                
                // Stats Footer Row
                HStack(spacing: 12) {
                    Label(result.chapterInfo, systemImage: "book")
                    Label("\(result.wordCount) words", systemImage: "character")
                    Spacer()
                    Label(result.kudos, systemImage: "hand.thumbsup")
                    Label(result.hits, systemImage: "eye")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}
