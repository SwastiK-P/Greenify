//
//  VideoCard.swift
//  Greenify
//
//  Created for video card display
//

import SwiftUI

struct VideoCard: View {
    let video: YouTubeVideo
    
    var body: some View {
        Button(action: {
            HapticManager.shared.mediumImpact()
            // Open directly in YouTube app or Safari for reliable playback
            YouTubeVideoURLHelper.openInYouTubeApp(videoId: video.id)
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail with play button overlay
                ZStack(alignment: .center) {
                    AsyncImage(url: URL(string: video.thumbnailURL)) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    ProgressView()
                                        .tint(.green)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        case .failure:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                    // Play button overlay
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: 2) // Slight offset for visual centering
                    }
                    
                    // Duration badge (bottom right)
                    if !video.formattedDuration.isEmpty {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text(video.formattedDuration)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(6)
                                    .padding(8)
                            }
                        }
                    }
                }
                .cornerRadius(16)
                
                // Video info
                VStack(alignment: .leading, spacing: 8) {
                    Text(video.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(video.channelTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Label {
                            Text(video.formattedDate)
                                .font(.system(size: 12, weight: .regular))
                        } icon: {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.secondary)
                        
                        if !video.formattedDuration.isEmpty {
                            Label {
                                Text(video.formattedDuration)
                                    .font(.system(size: 12, weight: .regular))
                            } icon: {
                                Image(systemName: "clock")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(16)
            }
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
    }
}

struct VideoPlayerSheet: View {
    let video: YouTubeVideo
    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if showError {
                    // Error state - show option to open in YouTube
                    VStack(spacing: 24) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.7))
                        
                        VStack(spacing: 12) {
                            Text("Unable to play video")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Open in YouTube to watch this video")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            HapticManager.shared.mediumImpact()
                            YouTubeVideoURLHelper.openInYouTubeApp(videoId: video.id)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Open in YouTube")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Close")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(40)
                } else {
                    VideoPlayerView(videoId: video.id) {
                        // Error handler - show error state
                        showError = true
                    }
                    .ignoresSafeArea()
                }
            }
            .navigationTitle(video.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}
