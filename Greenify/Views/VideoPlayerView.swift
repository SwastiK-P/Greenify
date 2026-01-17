//
//  VideoPlayerView.swift
//  Greenify
//
//  Created for native video player
//

import SwiftUI
import WebKit

struct VideoPlayerView: UIViewRepresentable {
    let videoId: String
    let onError: (() -> Void)?
    
    init(videoId: String, onError: (() -> Void)? = nil) {
        self.videoId = videoId
        self.onError = onError
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        context.coordinator.onError = onError
        
        // YouTube embed URL with better parameters
        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                html, body {
                    width: 100%;
                    height: 100%;
                    overflow: hidden;
                    background-color: #000;
                }
                .container {
                    position: relative;
                    width: 100%;
                    height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                iframe {
                    width: 100%;
                    height: 100%;
                    border: none;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <iframe
                    id="player"
                    src="https://www.youtube.com/embed/\(videoId)?autoplay=1&playsinline=1&rel=0&modestbranding=1&enablejsapi=1"
                    frameborder="0"
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                    allowfullscreen>
                </iframe>
            </div>
            <script>
                window.addEventListener('message', function(event) {
                    if (event.data === 'error' || event.data.type === 'error') {
                        window.webkit.messageHandlers.errorHandler.postMessage('error');
                    }
                });
                
                // Check for iframe load errors
                var iframe = document.getElementById('player');
                iframe.onerror = function() {
                    window.webkit.messageHandlers.errorHandler.postMessage('error');
                };
            </script>
        </body>
        </html>
        """
        
        // Add message handler for error detection
        let contentController = webView.configuration.userContentController
        contentController.add(context.coordinator, name: "errorHandler")
        
        webView.loadHTMLString(embedHTML, baseURL: URL(string: "https://www.youtube.com"))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var onError: (() -> Void)?
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "errorHandler" {
                DispatchQueue.main.async {
                    self.onError?()
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.onError?()
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.onError?()
            }
        }
    }
}

// Helper to open YouTube videos
struct YouTubeVideoURLHelper {
    static func openInYouTubeApp(videoId: String) {
        // Try to open in YouTube app first
        if let youtubeURL = URL(string: "youtube://watch?v=\(videoId)"),
           UIApplication.shared.canOpenURL(youtubeURL) {
            UIApplication.shared.open(youtubeURL)
        } else if let webURL = URL(string: "https://www.youtube.com/watch?v=\(videoId)") {
            UIApplication.shared.open(webURL)
        }
    }
}
