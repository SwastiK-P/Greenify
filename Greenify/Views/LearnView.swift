//
//  LearnView.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import SwiftUI

enum ContentType: String, CaseIterable {
    case articles = "Articles"
    case videos = "Videos"
}

// MARK: - Color Helpers
extension ArticleCategory {
    var colorValue: Color {
        switch self.color {
        case "red": return .red
        case "yellow": return .yellow
        case "brown": return .brown
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        default: return .green
        }
    }
}

extension DifficultyLevel {
    var colorValue: Color {
        switch self.color {
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .green
        }
    }
}

struct LearnView: View {
    @ObservedObject var viewModel: LearnViewModel
    @State private var showingFilters = false
    @State private var showingBookmarks = false
    @State private var selectedContentType: ContentType = .articles
    
    var body: some View {
        NavigationView {
            ZStack {
                // Subtle green background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.green.opacity(0.10),
                        Color(.systemBackground).opacity(0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Segmented Control
                    segmentedControl
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    
                    // Content
                    if viewModel.isLoading {
                        LoadingView(message: "Loading articles...")
                    } else {
                        contentView
                    }
                }
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Search articles")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        showingBookmarks = true
                    }) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        showingFilters = true
                    }) {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(hasActiveFilters ? .green : .primary)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                ArticleFiltersView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingBookmarks) {
                BookmarkedArticlesView(viewModel: viewModel)
            }
            .refreshable {
                HapticManager.shared.mediumImpact()
                viewModel.refreshArticles()
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        viewModel.selectedCategory != nil || viewModel.selectedDifficulty != nil
    }
    
    private var segmentedControl: some View {
        Picker("Content Type", selection: $selectedContentType) {
            ForEach(ContentType.allCases, id: \.self) { type in
                Text(type.rawValue)
                    .tag(type)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedContentType) { _ in
            HapticManager.shared.selection()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedContentType {
        case .articles:
            articlesContent
        case .videos:
            videosContent
        }
    }
    
    private var activeFiltersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if let category = viewModel.selectedCategory {
                    FilterChip(
                        title: category.rawValue,
                        icon: category.icon
                    ) {
                        HapticManager.shared.lightImpact()
                        viewModel.selectedCategory = nil
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                if let difficulty = viewModel.selectedDifficulty {
                    FilterChip(
                        title: difficulty.rawValue,
                        icon: difficulty.icon
                    ) {
                        HapticManager.shared.lightImpact()
                        viewModel.selectedDifficulty = nil
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                Button(action: {
                    HapticManager.shared.mediumImpact()
                    viewModel.clearFilters()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                        Text("Clear All")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(Color.red.opacity(0.12))
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
            .padding(.horizontal, 4)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasActiveFilters)
    }
    
    private var articlesContent: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                // Active Filters
                if hasActiveFilters {
                    activeFiltersSection
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }
                
                // Articles Section
                articlesSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    private var videosContent: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                // Videos Section
                videosSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    private var articlesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                if !viewModel.searchText.isEmpty || hasActiveFilters {
                    Text("\(viewModel.filteredArticles.count) \(viewModel.filteredArticles.count == 1 ? "article" : "articles")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background {
                            Capsule()
                                .fill(Color(.systemGray6))
                        }
                }
            }
            
            if viewModel.filteredArticles.isEmpty {
                EmptyStateView(
                    icon: "doc.text.fill",
                    title: "No Articles Found",
                    subtitle: viewModel.searchText.isEmpty ? 
                        "No articles match your current filters." :
                        "No articles match your search criteria.",
                    actionTitle: viewModel.searchText.isEmpty ? nil : "Clear Search"
                ) {
                    if !viewModel.searchText.isEmpty {
                        HapticManager.shared.mediumImpact()
                        viewModel.searchText = ""
                    }
                }
                .padding(.vertical, 40)
            } else {
                ForEach(Array(viewModel.filteredArticles.enumerated()), id: \.element.id) { index, article in
                    ArticleCard(article: article, viewModel: viewModel)
                }
            }
        }
    }
    
    private var videosSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            EmptyStateView(
                icon: "play.rectangle.fill",
                title: "No Videos Yet",
                subtitle: "Video content will be available soon.",
                actionTitle: nil
            )
            .padding(.vertical, 40)
        }
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let onRemove: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.15),
                            Color.green.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        }
        .foregroundColor(.green)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}



struct ArticleCard: View {
    let article: Article
    @ObservedObject var viewModel: LearnViewModel
    
    private var limitedTags: [String] {
        Array(article.tags.prefix(3))
    }
    
    var body: some View {
        NavigationLink(destination: ArticleDetailView(article: article, viewModel: viewModel)) {
            VStack(alignment: .leading, spacing: 14) {
                // Header with bookmark button
                HStack(alignment: .top, spacing: 16) {
                    // Article Icon (SF Symbol)
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        article.category.colorValue.opacity(0.2),
                                        article.category.colorValue.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: article.imageSystemName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(article.category.colorValue)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text(article.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .lineSpacing(2)
                        
                        Text(article.summary)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(1)
                    }
                    
                    Spacer()
                    
                    // Bookmark button - top right aligned
                    Button(action: {
                        HapticManager.shared.mediumImpact()
                        viewModel.toggleBookmark(for: article.id)
                    }) {
                        Image(systemName: viewModel.isBookmarked(article.id) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(viewModel.isBookmarked(article.id) ? .green : .secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Tags - Limited to 3
                if !limitedTags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(limitedTags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background {
                                    Capsule()
                                        .fill(Color(.systemGray6))
                                }
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Footer
                HStack(alignment: .center) {
                    Label {
                        Text("\(article.readingTime) min")
                            .font(.system(size: 14, weight: .semibold))
                    } icon: {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    CategoryBadge(category: article.category)
                    
                    DifficultyBadge(difficulty: article.difficulty)
                }
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 3)
                    .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(.systemGray5), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            HapticManager.shared.lightImpact()
        }
    }
}

struct CategoryBadge: View {
    let category: ArticleCategory
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: category.icon)
                .font(.system(size: 11, weight: .semibold))
            
            Text(category.rawValue)
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            category.colorValue.opacity(0.15),
                            category.colorValue.opacity(0.1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .foregroundColor(category.colorValue)
    }
}

struct DifficultyBadge: View {
    let difficulty: DifficultyLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: difficulty.icon)
                .font(.system(size: 11, weight: .semibold))
            
            Text(difficulty.rawValue)
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            difficulty.colorValue.opacity(0.15),
                            difficulty.colorValue.opacity(0.1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .foregroundColor(difficulty.colorValue)
    }
}

struct ArticleDetailView: View {
    let article: Article
    @ObservedObject var viewModel: LearnViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                headerSection
                
                // Content
                contentSection
                
                // Related Articles
                relatedArticlesSection
            }
            .padding(20)
        }
        .navigationTitle("Article")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    HapticManager.shared.mediumImpact()
                    viewModel.toggleBookmark(for: article.id)
                }) {
                    Image(systemName: viewModel.isBookmarked(article.id) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(viewModel.isBookmarked(article.id) ? .green : .primary)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Category and Difficulty
            HStack {
                CategoryBadge(category: article.category)
                
                Spacer()
                
                DifficultyBadge(difficulty: article.difficulty)
            }
            
            // Title
            Text(article.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
            
            // Metadata
            HStack(spacing: 20) {
                Label {
                    Text("\(article.readingTime) min read")
                        .font(.system(size: 15, weight: .medium))
                } icon: {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                }
                .foregroundColor(.secondary)
                
                Label {
                    Text(article.formattedDate)
                        .font(.system(size: 15, weight: .medium))
                } icon: {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                }
                .foregroundColor(.secondary)
            }
            
            // Summary
            Text(article.summary)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Formatted content with proper markdown-style formatting
            FormattedArticleContentView(content: article.content)
            
            // Tags
            if !article.tags.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tags")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                        ForEach(article.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background {
                                    Capsule()
                                        .fill(Color(.systemGray6))
                                }
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private var relatedArticlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Related Articles")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            let relatedArticles = viewModel.getRecommendedArticles(for: article)
            
            if relatedArticles.isEmpty {
                Text("No related articles found.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(relatedArticles) { relatedArticle in
                    ArticleCard(article: relatedArticle, viewModel: viewModel)
                }
            }
        }
    }
}

struct ArticleFiltersView: View {
    @ObservedObject var viewModel: LearnViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        HapticManager.shared.selection()
                        viewModel.selectedCategory = nil
                    }) {
                        HStack {
                            Text("All Categories")
                                .foregroundColor(.primary)
                                .font(.system(size: 16, weight: .medium))
                            
                            Spacer()
                            
                            if viewModel.selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                    }
                    
                    ForEach(ArticleCategory.allCases, id: \.self) { category in
                        Button(action: {
                            HapticManager.shared.selection()
                            viewModel.selectedCategory = category
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.colorValue)
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 28)
                                
                                Text(category.rawValue)
                                    .foregroundColor(.primary)
                                    .font(.system(size: 16, weight: .regular))
                                
                                Spacer()
                                
                                if viewModel.selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Category")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: {
                        HapticManager.shared.selection()
                        viewModel.selectedDifficulty = nil
                    }) {
                        HStack {
                            Text("All Levels")
                                .foregroundColor(.primary)
                                .font(.system(size: 16, weight: .medium))
                            
                            Spacer()
                            
                            if viewModel.selectedDifficulty == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                    }
                    
                    ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                        Button(action: {
                            HapticManager.shared.selection()
                            viewModel.selectedDifficulty = difficulty
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: difficulty.icon)
                                    .foregroundColor(difficulty.colorValue)
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 28)
                                
                                Text(difficulty.rawValue)
                                    .foregroundColor(.primary)
                                    .font(.system(size: 16, weight: .regular))
                                
                                Spacer()
                                
                                if viewModel.selectedDifficulty == difficulty {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Difficulty")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Filter Articles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        HapticManager.shared.mediumImpact()
                        viewModel.clearFilters()
                    }) {
                        Text("Clear All")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(hasActiveFilters ? .red : .secondary)
                    }
                    .disabled(!hasActiveFilters)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        viewModel.selectedCategory != nil || viewModel.selectedDifficulty != nil
    }
}

struct BookmarkedArticlesView: View {
    @ObservedObject var viewModel: LearnViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                let bookmarkedArticles = viewModel.getBookmarkedArticles()
                
                if bookmarkedArticles.isEmpty {
                    EmptyStateView(
                        icon: "bookmark.fill",
                        title: "No Bookmarks",
                        subtitle: "Bookmark articles you want to read later by tapping the bookmark icon."
                    )
                } else {
                    List {
                        ForEach(bookmarkedArticles) { article in
                            NavigationLink(destination: ArticleDetailView(article: article, viewModel: viewModel)) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        article.category.colorValue.opacity(0.2),
                                                        article.category.colorValue.opacity(0.1)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: article.imageSystemName)
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(article.category.colorValue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(article.title)
                                            .font(.system(size: 17, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                            .lineSpacing(2)
                                        
                                        HStack {
                                            CategoryBadge(category: article.category)
                                            
                                            Spacer()
                                            
                                            Label {
                                                Text("\(article.readingTime) min")
                                                    .font(.system(size: 12, weight: .medium))
                                            } icon: {
                                                Image(systemName: "clock.fill")
                                                    .font(.system(size: 11))
                                            }
                                            .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .onDelete { indexSet in
                            HapticManager.shared.mediumImpact()
                            for index in indexSet {
                                let article = bookmarkedArticles[index]
                                viewModel.toggleBookmark(for: article.id)
                            }

                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
}

// MARK: - Formatted Article Content View

struct FormattedArticleContentView: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(parseContent(), id: \.id) { element in
                element.view
            }
        }
    }
    
    private func parseContent() -> [ContentElement] {
        var elements: [ContentElement] = []
        let lines = content.components(separatedBy: .newlines)
        var currentParagraph: [String] = []
        var currentList: [String] = []
        var currentListType: ListType = .bullet
        
        enum ListType {
            case bullet
            case numbered
        }
        
        func flushCurrentList() {
            if !currentList.isEmpty {
                switch currentListType {
                case .bullet:
                    elements.append(.bulletList(currentList))
                case .numbered:
                    elements.append(.numberedList(currentList))
                }
                currentList = []
            }
        }
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty {
                // Empty line - flush current content
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                flushCurrentList()
                continue
            }
            
            // Check for headings
            if trimmed.hasPrefix("## ") {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                flushCurrentList()
                let headingText = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                elements.append(.heading2(headingText))
            } else if trimmed.hasPrefix("### ") {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                flushCurrentList()
                let headingText = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                elements.append(.heading3(headingText))
            }
            // Check for bullet lists
            else if trimmed.hasPrefix("- ") {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                // If we were in a numbered list, flush it first
                if currentListType == .numbered {
                    flushCurrentList()
                }
                currentListType = .bullet
                let listItem = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                currentList.append(listItem)
            }
            // Check for numbered lists
            else if let numberMatch = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                // If we were in a bullet list, flush it first
                if currentListType == .bullet {
                    flushCurrentList()
                }
                currentListType = .numbered
                let listItem = String(trimmed[numberMatch.upperBound...]).trimmingCharacters(in: .whitespaces)
                currentList.append(listItem)
            }
            // Regular paragraph text
            else {
                flushCurrentList()
                currentParagraph.append(trimmed)
            }
        }
        
        // Flush remaining content
        if !currentParagraph.isEmpty {
            elements.append(.paragraph(currentParagraph.joined(separator: " ")))
        }
        flushCurrentList()
        
        return elements
    }
}

enum ContentElement: Identifiable {
    case heading2(String)
    case heading3(String)
    case paragraph(String)
    case bulletList([String])
    case numberedList([String])
    
    var id: String {
        switch self {
        case .heading2(let text): return "h2-\(text)"
        case .heading3(let text): return "h3-\(text)"
        case .paragraph(let text): return "p-\(text.prefix(20))"
        case .bulletList(let items): return "bullet-\(items.count)"
        case .numberedList(let items): return "numbered-\(items.count)"
        }
    }
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .heading2(let text):
            Text(cleanMarkdown(text))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
        case .heading3(let text):
            Text(cleanMarkdown(text))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.top, 12)
                .padding(.bottom, 6)
            
        case .paragraph(let text):
            Text(cleanMarkdown(text))
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.primary)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)
            
        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.7))
                            .frame(width: 6, height: 6)
                            .padding(.top, 8)
                        
                        Text(cleanMarkdown(item))
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.primary)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.leading, 8)
            
        case .numberedList(let items):
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .frame(width: 30, alignment: .trailing)
                            .padding(.top, 2)
                        
                        Text(cleanMarkdown(item))
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.primary)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.leading, 8)
        }
    }
    
    private func cleanMarkdown(_ text: String) -> String {
        var cleaned = text
        // Remove bold markers
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")
        cleaned = cleaned.replacingOccurrences(of: "__", with: "")
        // Remove italic markers (but preserve bullets)
        cleaned = cleaned.replacingOccurrences(of: #"(?<!^)(?<![\s\-])\*(?!\*)"#, with: "", options: .regularExpression)
        // Remove code blocks
        cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        cleaned = cleaned.replacingOccurrences(of: "`", with: "")
        return cleaned.trimmingCharacters(in: .whitespaces)
    }
}

#Preview {
    LearnView(viewModel: LearnViewModel())
}

