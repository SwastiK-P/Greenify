# Greenify - Sustainability iOS App

A comprehensive SwiftUI iOS app focused on sustainability and environmental awareness, built with modern iOS design principles and MVVM architecture.

## Features

### 🏠 Home Tab
- Carbon footprint summary with daily, weekly, monthly projections
- Sustainability rating with personalized feedback
- Quick action buttons for easy navigation
- Daily sustainability tips
- Progress tracking towards emission goals

### 🧮 Carbon Calculator Tab
- Interactive carbon footprint calculator
- Activity-based emissions tracking (Transport, Electricity, Food, etc.)
- Real-time calculations with visual feedback
- Detailed emission breakdowns by category
- Sustainability recommendations
- Time period projections (daily, weekly, monthly, yearly)

### 📷 Scan Tab
- Camera-based item scanning for recyclability
- AI-powered item recognition (simulated)
- Disposal instructions and environmental impact info
- Sustainable alternatives suggestions
- Scan history tracking
- Recyclability statistics

### ♻️ Recycling Tab
- Interactive map of nearby recycling centers
- Material-based filtering (Plastic, Paper, Glass, Metal, etc.)
- Detailed center information with operating hours
- Distance-based sorting
- Contact information and directions
- Comprehensive recycling tips

### 📚 Learn Tab
- Educational articles on sustainability topics
- Category-based filtering (Climate Change, Renewable Energy, etc.)
- Difficulty levels (Beginner, Intermediate, Advanced)
- Bookmark functionality
- Search and filtering capabilities
- Reading progress tracking

## Architecture

### MVVM Pattern
- **Models**: Data structures for carbon footprint, recycling centers, articles, and scanned items
- **ViewModels**: Business logic and state management with `@ObservableObject`
- **Views**: SwiftUI views with clean separation of concerns

### Key Components
- **Reusable UI Components**: CardView, StatCardView, ActionCardView, ChartView, EmptyStateView
- **Data Models**: CarbonFootprint, RecyclingCenter, Article, ScannedItem with mock data
- **ViewModels**: Reactive state management with Combine framework

## Technical Features

### Modern iOS Design
- iOS 16+ design language with clean, Apple-like aesthetics
- Dynamic Type support for accessibility
- Dark mode compatibility
- Smooth animations and transitions
- Native SwiftUI components

### Performance Optimizations
- Lazy loading for large lists
- Efficient state management
- Debounced search functionality
- Memory-efficient image handling

### User Experience
- Intuitive navigation with TabView
- Pull-to-refresh functionality
- Search and filtering capabilities
- Contextual empty states
- Loading indicators

## Mock Data

The app includes comprehensive mock data for demonstration:
- **Activities**: 15+ predefined activities with emission factors
- **Recycling Centers**: 4 mock centers with realistic data
- **Articles**: 5 detailed educational articles
- **Scan Results**: 5 different item types with disposal instructions

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository
2. Open `Greenify.xcodeproj` in Xcode
3. Build and run on simulator or device

## Future Enhancements

- Real API integration for recycling centers
- CoreML integration for actual item recognition
- User authentication and data persistence
- Social features and community challenges
- Push notifications for sustainability reminders
- Apple Watch companion app

## License

This project is created for educational purposes and demonstrates modern iOS development practices with SwiftUI and MVVM architecture.