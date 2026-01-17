//
//  YouTubeVideo.swift
//  Greenify
//
//  Created for YouTube video model
//

import Foundation

struct YouTubeVideo: Identifiable, Codable {
    let id: String // YouTube video ID
    let title: String
    let description: String
    let thumbnailURL: String
    let channelTitle: String
    let publishedAt: Date
    let duration: String? // ISO 8601 duration format
    
    var videoURL: String {
        "https://www.youtube.com/watch?v=\(id)"
    }
    
    var embedURL: String {
        "https://www.youtube.com/embed/\(id)"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: publishedAt)
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "" }
        // Parse ISO 8601 duration (PT4M13S -> 4:13)
        if let regex = try? NSRegularExpression(pattern: "PT(?:([0-9]+)H)?(?:([0-9]+)M)?(?:([0-9]+)S)?", options: []),
           let match = regex.firstMatch(in: duration, range: NSRange(duration.startIndex..., in: duration)) {
            var hours = ""
            var minutes = "0"
            var seconds = "0"
            
            if let hoursRange = Range(match.range(at: 1), in: duration) {
                hours = String(duration[hoursRange])
            }
            if let minutesRange = Range(match.range(at: 2), in: duration) {
                minutes = String(duration[minutesRange])
            }
            if let secondsRange = Range(match.range(at: 3), in: duration) {
                seconds = String(duration[secondsRange])
            }
            
            if !hours.isEmpty {
                return "\(hours):\(String(format: "%02d", Int(minutes) ?? 0)):\(String(format: "%02d", Int(seconds) ?? 0))"
            } else {
                return "\(minutes):\(String(format: "%02d", Int(seconds) ?? 0))"
            }
        }
        return duration
    }
    
    // Get duration in seconds for filtering
    var durationInSeconds: Int? {
        guard let duration = duration else { return nil }
        // Parse ISO 8601 duration (PT4M13S -> 253 seconds)
        if let regex = try? NSRegularExpression(pattern: "PT(?:([0-9]+)H)?(?:([0-9]+)M)?(?:([0-9]+)S)?", options: []),
           let match = regex.firstMatch(in: duration, range: NSRange(duration.startIndex..., in: duration)) {
            var totalSeconds = 0
            
            if let hoursRange = Range(match.range(at: 1), in: duration) {
                let hours = Int(String(duration[hoursRange])) ?? 0
                totalSeconds += hours * 3600
            }
            if let minutesRange = Range(match.range(at: 2), in: duration) {
                let minutes = Int(String(duration[minutesRange])) ?? 0
                totalSeconds += minutes * 60
            }
            if let secondsRange = Range(match.range(at: 3), in: duration) {
                let seconds = Int(String(duration[secondsRange])) ?? 0
                totalSeconds += seconds
            }
            
            return totalSeconds
        }
        return nil
    }
    
    // Check if video is a Short (60 seconds or less, or contains #shorts in title)
    var isShort: Bool {
        // Check title for #shorts indicator (with hash symbol)
        if title.localizedCaseInsensitiveContains("#shorts") {
            return true
        }
        
        // Check duration (60 seconds or less)
        if let durationSeconds = durationInSeconds, durationSeconds <= 60 {
            return true
        }
        
        return false
    }
}

// MARK: - YouTube API Response Models

struct YouTubeSearchResponse: Codable {
    let items: [YouTubeSearchItem]
}

struct YouTubeSearchItem: Codable {
    let id: YouTubeVideoId
    let snippet: YouTubeSnippet
    let contentDetails: YouTubeContentDetails?
}

struct YouTubeVideoId: Codable {
    let videoId: String
}

struct YouTubeSnippet: Codable {
    let title: String
    let description: String
    let thumbnails: YouTubeThumbnails
    let channelTitle: String
    let publishedAt: String
}

struct YouTubeThumbnails: Codable {
    let medium: YouTubeThumbnail?
    let high: YouTubeThumbnail?
    let standard: YouTubeThumbnail?
    
    var bestThumbnail: YouTubeThumbnail? {
        standard ?? high ?? medium
    }
}

struct YouTubeThumbnail: Codable {
    let url: String
    let width: Int
    let height: Int
}

struct YouTubeContentDetails: Codable {
    let duration: String
}
