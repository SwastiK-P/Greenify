//
//  LearnView.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import SwiftUI

struct LearnView: View {
    @ObservedObject var viewModel: LearnViewModel
    @State private var showingFilters = false
    @State private var showingBookmarks = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchSection
                
                // Content
                if viewModel.isLoading {
                    LoadingView(message: "Loading articles...")
                } else if viewModel.filteredArticles.isEmpty {
                    EmptyStateView(
                        icon: "book.fill",
                        title: "No Articles Found",
                        subtitle: viewModel.searchText.isEmpty ? 
                            "No articles available at the moment." :
                            "No articles match your search criteria.",
                        actionTitle: viewModel.searchText.isEmpty ? "Refresh" : "Clear Filters"
                    ) {
                        if viewModel.searchText.isEmpty {
                            viewModel.refreshArticles()
                        } else {
                            viewModel.clearFilters()
                        }
                    }
                } else {
                    articlesContent
                }
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingBookmarks = true
                    }) {
                        Image(systemName: "bookmark.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFilters = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(hasActiveFilters ? .blue : .primary)
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
                viewModel.refreshArticles()
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        viewModel.selectedCategory != nil || viewModel.selectedDifficulty != nil
    }
    
    private var searchSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search articles", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Active Filters
            if hasActiveFilters {
                activeFiltersSection
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private var activeFiltersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let category = viewModel.selectedCategory {
                    FilterChip(
                        title: category.rawValue,
                        icon: category.icon
                    ) {
                        viewModel.selectedCategory = nil
                    }
                }
                
                if let difficulty = viewModel.selectedDifficulty {
                    FilterChip(
                        title: difficulty.rawValue,
                        icon: difficulty.icon
                    ) {
                        viewModel.selectedDifficulty = nil
                    }
                }
                
                Button("Clear All") {
                    viewModel.clearFilters()
                }
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(16)
            }
            .padding(.horizontal)
        }
    }
    
    private var articlesContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Featured Article
                if let featuredArticle = viewModel.filteredArticles.first {
                    FeaturedArticleCard(article: featuredArticle, viewModel: viewModel)
                }
                
                // Recent Articles
                if viewModel.searchText.isEmpty && !hasActiveFilters {
                    recentArticlesSection
                }
                
                // All Articles
                allArticlesSection
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
    
    private var recentArticlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Articles")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.getRecentArticles()) { article in
                        CompactArticleCard(article: article, viewModel: viewModel)
                            .frame(width: 280)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var allArticlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(viewModel.searchText.isEmpty && !hasActiveFilters ? "All Articles" : "Search Results")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(viewModel.filteredArticles.count) articles")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            
            ForEach(viewModel.filteredArticles) { article in
                ArticleCard(article: article, viewModel: viewModel)
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(16)
    }
}

struct FeaturedArticleCard: View {
    let article: Article
    @ObservedObject var viewModel: LearnViewModel
    
    var body: some View {
        NavigationLink(destination: ArticleDetailView(article: article, viewModel: viewModel)) {
            CardView(backgroundColor: Color.blue.opacity(0.1)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("⭐ Featured")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.toggleBookmark(for: article.id)
                        }) {
                            Image(systemName: viewModel.isBookmarked(article.id) ? "bookmark.fill" : "bookmark")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(article.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(article.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        CategoryBadge(category: article.category)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Label("\(article.readingTime) min", systemImage: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            DifficultyBadge(difficulty: article.difficulty)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CompactArticleCard: View {
    let article: Article
    @ObservedObject var viewModel: LearnViewModel
    
    var body: some View {
        NavigationLink(destination: ArticleDetailView(article: article, viewModel: viewModel)) {
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        CategoryBadge(category: article.category)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.toggleBookmark(for: article.id)
                        }) {
                            Image(systemName: viewModel.isBookmarked(article.id) ? "bookmark.fill" : "bookmark")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(article.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Text(article.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Label("\(article.readingTime) min", systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        DifficultyBadge(difficulty: article.difficulty)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ArticleCard: View {
    let article: Article
    @ObservedObject var viewModel: LearnViewModel
    
    var body: some View {
        NavigationLink(destination: ArticleDetailView(article: article, viewModel: viewModel)) {
            CardView {
                HStack(spacing: 16) {
                    // Article Icon
                    Image(systemName: article.imageSystemName)
                        .font(.title)
                        .foregroundColor(Color(article.category.color))
                        .frame(width: 50, height: 50)
                        .background(Color(article.category.color).opacity(0.1))
                        .cornerRadius(10)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text(article.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        
                        Text(article.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        HStack {
                            CategoryBadge(category: article.category)
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Label("\(article.readingTime) min", systemImage: "clock.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    viewModel.toggleBookmark(for: article.id)
                                }) {
                                    Image(systemName: viewModel.isBookmarked(article.id) ? "bookmark.fill" : "bookmark")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryBadge: View {
    let category: ArticleCategory
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption2)
            
            Text(category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(category.color).opacity(0.1))
        .foregroundColor(Color(category.color))
        .cornerRadius(8)
    }
}

struct DifficultyBadge: View {
    let difficulty: DifficultyLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: difficulty.icon)
                .font(.caption2)
            
            Text(difficulty.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(difficulty.color).opacity(0.1))
        .foregroundColor(Color(difficulty.color))
        .cornerRadius(8)
    }
}

struct ArticleDetailView: View {
    let article: Article
    @ObservedObject var viewModel: LearnViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                // Content
                contentSection
                
                // Related Articles
                relatedArticlesSection
            }
            .padding()
        }
        .navigationTitle("Article")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.toggleBookmark(for: article.id)
                }) {
                    Image(systemName: viewModel.isBookmarked(article.id) ? "bookmark.fill" : "bookmark")
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category and Difficulty
            HStack {
                CategoryBadge(category: article.category)
                
                Spacer()
                
                DifficultyBadge(difficulty: article.difficulty)
            }
            
            // Title
            Text(article.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            // Metadata
            HStack(spacing: 16) {
                Label("\(article.readingTime) min read", systemImage: "clock.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Label(article.formattedDate, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Summary
            Text(article.summary)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(article.content)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            // Tags
            if !article.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(article.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .foregroundColor(.secondary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
    
    private var relatedArticlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Articles")
                .font(.headline)
                .foregroundColor(.primary)
            
            let relatedArticles = viewModel.getRecommendedArticles(for: article)
            
            if relatedArticles.isEmpty {
                Text("No related articles found.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(relatedArticles) { relatedArticle in
                    CompactArticleCard(article: relatedArticle, viewModel: viewModel)
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
                Section("Category") {
                    Button(action: {
                        viewModel.selectedCategory = nil
                    }) {
                        HStack {
                            Text("All Categories")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if viewModel.selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    ForEach(ArticleCategory.allCases, id: \.self) { category in
                        Button(action: {
                            viewModel.selectedCategory = category
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(Color(category.color))
                                    .frame(width: 24)
                                
                                Text(category.rawValue)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if viewModel.selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Difficulty") {
                    Button(action: {
                        viewModel.selectedDifficulty = nil
                    }) {
                        HStack {
                            Text("All Levels")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if viewModel.selectedDifficulty == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                        Button(action: {
                            viewModel.selectedDifficulty = difficulty
                        }) {
                            HStack {
                                Image(systemName: difficulty.icon)
                                    .foregroundColor(Color(difficulty.color))
                                    .frame(width: 24)
                                
                                Text(difficulty.rawValue)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if viewModel.selectedDifficulty == difficulty {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Articles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        viewModel.clearFilters()
                    }
                    .disabled(!hasActiveFilters)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
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
                                HStack(spacing: 12) {
                                    Image(systemName: article.imageSystemName)
                                        .font(.title2)
                                        .foregroundColor(Color(article.category.color))
                                        .frame(width: 40, height: 40)
                                        .background(Color(article.category.color).opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(article.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                        
                                        HStack {
                                            CategoryBadge(category: article.category)
                                            
                                            Spacer()
                                            
                                            Label("\(article.readingTime) min", systemImage: "clock.fill")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let article = bookmarkedArticles[index]
                                viewModel.toggleBookmark(for: article.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LearnView(viewModel: LearnViewModel())
}