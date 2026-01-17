//
//  LearnViewModel.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import Foundation
import Combine

@MainActor
class LearnViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var filteredArticles: [Article] = []
    @Published var selectedCategory: ArticleCategory?
    @Published var selectedDifficulty: DifficultyLevel?
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var bookmarkedArticles: Set<UUID> = []
    
    // Video properties
    @Published var videos: [YouTubeVideo] = []
    @Published var isLoadingVideos = false
    @Published var videoError: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let youtubeService: YouTubeService
    
    init() {
        youtubeService = YouTubeService(apiKey: Config.youtubeAPIKey)
        loadArticles()
        setupBindings()
        loadBookmarks()
        loadVideos()
    }
    
    private func loadArticles() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.articles = Article.mockArticles
            self?.filteredArticles = Article.mockArticles
            self?.isLoading = false
        }
    }
    
    private func setupBindings() {
        // Combine search text, category, and difficulty filters
        Publishers.CombineLatest3($searchText, $selectedCategory, $selectedDifficulty)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText, category, difficulty in
                self?.filterArticles(searchText: searchText, category: category, difficulty: difficulty)
            }
            .store(in: &cancellables)
    }
    
    private func filterArticles(searchText: String, category: ArticleCategory?, difficulty: DifficultyLevel?) {
        var filtered = articles
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.summary.localizedCaseInsensitiveContains(searchText) ||
                article.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filter by category
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by difficulty
        if let difficulty = difficulty {
            filtered = filtered.filter { $0.difficulty == difficulty }
        }
        
        filteredArticles = filtered
    }
    
    func clearFilters() {
        selectedCategory = nil
        selectedDifficulty = nil
        searchText = ""
    }
    
    func toggleBookmark(for articleId: UUID) {
        if bookmarkedArticles.contains(articleId) {
            bookmarkedArticles.remove(articleId)
        } else {
            bookmarkedArticles.insert(articleId)
        }
        saveBookmarks()
    }
    
    func isBookmarked(_ articleId: UUID) -> Bool {
        return bookmarkedArticles.contains(articleId)
    }
    
    func getBookmarkedArticles() -> [Article] {
        return articles.filter { bookmarkedArticles.contains($0.id) }
    }
    
    func getArticlesByCategory() -> [ArticleCategory: [Article]] {
        return Dictionary(grouping: filteredArticles) { $0.category }
    }
    
    func getRecentArticles(limit: Int = 3) -> [Article] {
        return Array(articles.sorted { $0.publishedDate > $1.publishedDate }.prefix(limit))
    }
    
    func getRecommendedArticles(for article: Article, limit: Int = 3) -> [Article] {
        return articles
            .filter { $0.id != article.id }
            .filter { recommendedArticle in
                // Recommend articles with similar category or tags
                recommendedArticle.category == article.category ||
                !Set(recommendedArticle.tags).isDisjoint(with: Set(article.tags))
            }
            .sorted { $0.publishedDate > $1.publishedDate }
            .prefix(limit)
            .map { $0 }
    }
    
    func getReadingProgress() -> (totalArticles: Int, readArticles: Int, readingTime: Int) {
        let totalArticles = articles.count
        let readArticles = 0 // This would be tracked in a real app
        let totalReadingTime = articles.reduce(0) { $0 + $1.readingTime }
        
        return (totalArticles, readArticles, totalReadingTime)
    }
    
    private func saveBookmarks() {
        // In a real app, this would save to UserDefaults or Core Data
        let bookmarkIds = Array(bookmarkedArticles).map { $0.uuidString }
        UserDefaults.standard.set(bookmarkIds, forKey: "BookmarkedArticles")
    }
    
    private func loadBookmarks() {
        // In a real app, this would load from UserDefaults or Core Data
        if let bookmarkIds = UserDefaults.standard.array(forKey: "BookmarkedArticles") as? [String] {
            bookmarkedArticles = Set(bookmarkIds.compactMap { UUID(uuidString: $0) })
        }
    }
    
    func refreshArticles() {
        loadArticles()
    }
    
    // MARK: - Video Methods
    
    func loadVideos() {
        guard !Config.youtubeAPIKey.isEmpty && Config.youtubeAPIKey != "YOUR_YOUTUBE_API_KEY_HERE" else {
            videoError = "YouTube API key not configured"
            return
        }
        
        isLoadingVideos = true
        videoError = nil
        
        Task {
            do {
                // Request more results to account for Shorts being filtered out
                let fetchedVideos = try await youtubeService.searchVideos(query: "sustainability", maxResults: 30)
                await MainActor.run {
                    self.videos = fetchedVideos
                    self.isLoadingVideos = false
                }
            } catch {
                await MainActor.run {
                    self.videoError = error.localizedDescription
                    self.isLoadingVideos = false
                }
            }
        }
    }
    
    func refreshVideos() {
        loadVideos()
    }
}