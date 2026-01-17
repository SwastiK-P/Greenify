//
//  YouTubeService.swift
//  Greenify
//
//  Created for YouTube API integration
//

import Foundation

@MainActor
class YouTubeService {
    private let apiKey: String
    private let baseURL = "https://www.googleapis.com/youtube/v3"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func searchVideos(query: String, maxResults: Int = 20) async throws -> [YouTubeVideo] {
        guard !apiKey.isEmpty else {
            throw YouTubeError.missingAPIKey
        }
        
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "\(maxResults)"),
            URLQueryItem(name: "order", value: "relevance"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw YouTubeError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw YouTubeError.invalidResponse
        }
        
        let searchResponse = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
        
        // Get video details including duration
        let videoIds = searchResponse.items.map { $0.id.videoId }
        let videoDetails = try await getVideoDetails(videoIds: videoIds)
        
        // Combine search results with video details and filter out Shorts
        var videos: [YouTubeVideo] = []
        for item in searchResponse.items {
            let videoId = item.id.videoId
            let contentDetails = videoDetails[videoId]
            
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            let publishedDate = dateFormatter.date(from: item.snippet.publishedAt) ?? Date()
            
            let video = YouTubeVideo(
                id: videoId,
                title: item.snippet.title,
                description: item.snippet.description,
                thumbnailURL: item.snippet.thumbnails.bestThumbnail?.url ?? item.snippet.thumbnails.medium?.url ?? "",
                channelTitle: item.snippet.channelTitle,
                publishedAt: publishedDate,
                duration: contentDetails?.duration
            )
            
            // Filter out Shorts (videos 60 seconds or less, or containing #shorts)
            if !video.isShort {
                videos.append(video)
            }
        }
        
        return videos
    }
    
    private func getVideoDetails(videoIds: [String]) async throws -> [String: YouTubeContentDetails] {
        let idsString = videoIds.joined(separator: ",")
        
        var components = URLComponents(string: "\(baseURL)/videos")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "contentDetails"),
            URLQueryItem(name: "id", value: idsString),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw YouTubeError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw YouTubeError.invalidResponse
        }
        
        let detailsResponse = try JSONDecoder().decode(YouTubeDetailsResponse.self, from: data)
        
        // Create a mapping of videoId to contentDetails
        var detailsMap: [String: YouTubeContentDetails] = [:]
        for item in detailsResponse.items {
            detailsMap[item.id] = item.contentDetails
        }
        
        return detailsMap
    }
}

struct YouTubeDetailsResponse: Codable {
    let items: [YouTubeDetailItem]
}

struct YouTubeDetailItem: Codable {
    let id: String
    let contentDetails: YouTubeContentDetails
}

enum YouTubeError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "YouTube API key is missing"
        case .invalidURL:
            return "Invalid YouTube API URL"
        case .invalidResponse:
            return "Invalid response from YouTube API"
        case .decodingError:
            return "Failed to decode YouTube API response"
        }
    }
}
