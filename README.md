# 🌱 Greenify

> Making sustainability tracking as easy as having a conversation

A comprehensive iOS app that helps users track their carbon footprint through natural language conversations, find nearby recycling centers, scan items for recyclability, and learn about sustainable living.

[![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)

---

## ✨ Features

### 🧮 Chat-Based Carbon Calculator
- Natural language activity logging - just chat about your day
- AI-powered extraction using Google Gemini API
- Real-time CO₂ calculations with visual breakdowns
- Activity categories: Transport, Electricity, Food, Waste, Water

### 📷 AI Object Scanner
- Camera-based recyclability detection
- MobileNet V3 ML model for on-device recognition
- Instant disposal instructions and environmental impact
- Sustainable alternatives suggestions

### ♻️ Recycling Finder
- Interactive map of nearby recycling centers
- Material-based filtering (Plastic, Paper, Glass, Metal, etc.)
- Distance sorting and detailed center information

### 📚 Learn & Events
- Educational articles and YouTube videos
- Local carbon offset events with registration
- Bookmark and search functionality

### 🏠 Home Dashboard
- Carbon footprint summary (daily, weekly, monthly)
- Sustainability rating with personalized feedback
- Progress tracking and daily tips

---

## 🛠 Tech Stack

**Frontend:** SwiftUI • UIKit • MVVM • Combine  
**AI/ML:** Core ML • Vision Framework • MobileNet V3 • Google Gemini API  
**APIs:** Google Maps SDK • YouTube Data API • Mappls API  
**Platform:** iOS 16.0+ • Swift 5.9+ • Xcode 15.0+

---

## 📦 Installation

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/Greenify.git
   cd Greenify
   ```

2. Open `Greenify.xcodeproj` in Xcode

3. Configure API keys in `Greenify/Config.swift`:
   - **Gemini API Key** (Required) - Get from https://makersuite.google.com/app/apikey
   - **YouTube API Key** (Required) - Get from https://console.cloud.google.com/
   - **Mappls API Key** (Optional) - Get from https://developer.mappls.com/

4. Build and run (`Cmd + R`)

---

## 📱 Usage

### Log Activities via Chat
```
You: "I drove 15km to work"
AI: "What type of car?"
You: "Petrol car"
✅ Logged: Car (Petrol) - 15 km - 3.15 kg CO₂
```

### Scan Items
- Open Scan tab → Tap camera → Point at item → View recycling instructions

### Find Recycling Centers
- Open Recycling tab → View map/list → Filter by material → Get directions

---

## ⚙️ Configuration

Add your API keys in `Greenify/Config.swift`:

```swift
static let geminiAPIKey = "YOUR_GEMINI_API_KEY"
static let youtubeAPIKey = "YOUR_YOUTUBE_API_KEY"
static let mapplsAPIKey = "YOUR_MAPPLS_API_KEY" // Optional
```

⚠️ **Never commit API keys to version control!**

---

## 🏗 Architecture

**MVVM Pattern:**
- **Views** - SwiftUI UI layer
- **ViewModels** - Business logic with Combine
- **Models** - Data structures

**Key Components:**
- `CarbonCalculatorViewModel` - Chat-based tracking
- `ScanViewModel` - Object recognition
- `RecyclingViewModel` - Center management
- `GeminiService` - AI conversation
- `ObjectClassificationService` - ML model handling

---

## 📋 Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- API keys for Gemini and YouTube (see Configuration)

---

## 📄 License

This project is created for educational purposes and demonstrates modern iOS development with SwiftUI and MVVM architecture.

---

**Built with ❤️ for a sustainable future** 🌍
