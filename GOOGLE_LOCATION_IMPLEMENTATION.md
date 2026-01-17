# Google Location History - Full Implementation Guide

This document explains the complete implementation of Google Location History integration.

## ✅ What's Implemented

### 1. Google Sign-In Integration
- Full Google Sign-In SDK support (with fallback)
- OAuth 2.0 authentication
- Access token management
- User email capture

### 2. Google Takeout JSON Parser
- Complete parser for Google Takeout location history files
- Extracts trips, distances, and transport modes
- Filters data by date (today's trips)
- Handles waypoints and route data

### 3. Real-Time Location Tracking
- Core Location integration
- Background location tracking support
- Automatic trip detection (5-minute gap threshold)
- Transport mode detection based on speed

### 4. Transport Mode Detection
- Intelligent detection from Google activity data
- Fallback speed-based detection
- Supports: Driving, Walking, Cycling, Transit

### 5. Carbon Footprint Integration
- Automatic emission calculations
- Applies to carbon calculator
- Groups by transport mode

## 📋 Setup Instructions

### Step 1: Add Google Sign-In SDK

**Using Swift Package Manager:**

1. Open your project in Xcode
2. Go to **File > Add Package Dependencies...**
3. Enter the URL: `https://github.com/google/GoogleSignIn-iOS`
4. Select version: **Latest** (7.0.0 or newer)
5. Click **Add Package**
6. Select the **GoogleSignIn** product and click **Add Package**

### Step 2: Configure Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable **Google Sign-In API**
4. Go to **APIs & Services > Credentials**
5. Click **Create Credentials > OAuth 2.0 Client ID**
6. Select **iOS** as application type
7. Add your Bundle ID: `com.swastik.Greenify`
8. Copy the **Client ID**

### Step 3: Add Client ID to Config

Open `Greenify/Config.swift` and replace:
```swift
static let googleClientID = "YOUR_GOOGLE_CLIENT_ID_HERE"
```

With your actual Client ID:
```swift
static let googleClientID = "123456789-abcdefghijklmnop.apps.googleusercontent.com"
```

### Step 4: Configure URL Scheme (for Google Sign-In)

1. In Xcode, select your project
2. Select the **Greenify** target
3. Go to **Info** tab
4. Expand **URL Types**
5. Click **+** to add a new URL Type
6. Set:
   - **Identifier**: `GoogleSignIn`
   - **URL Schemes**: Your reversed Client ID (e.g., `com.googleusercontent.apps.123456789-abcdefghijklmnop`)

### Step 5: Update Info.plist (if needed)

The location usage descriptions are already configured. Ensure these are present:
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription` (for background tracking)

## 🚀 Usage

### Option 1: Import Google Takeout File

1. User exports location history from [Google Takeout](https://takeout.google.com/)
2. Select **Location History** only
3. Choose JSON format
4. Download and save the file
5. In the app, tap **"Import Google Takeout File"**
6. Select the downloaded JSON file
7. App automatically parses and processes the data

### Option 2: Real-Time Tracking

1. Grant location permissions when prompted
2. Tap **"Start Real-Time Tracking"**
3. App tracks your location in real-time
4. Automatically detects trips (5-minute gaps = new trip)
5. Tap **"Stop Tracking"** when done
6. Review detected trips and apply to calculator

### Option 3: Google API (Future)

Currently returns empty data. To implement:
- Use Google Location History API (if available)
- Or Google Maps Timeline API
- Requires additional API setup

## 🔧 Features

### Transport Mode Detection

**From Google Data:**
- Uses activity types: `IN_VEHICLE`, `ON_BICYCLE`, `WALKING`, `IN_BUS`, etc.
- Most accurate method

**Speed-Based Fallback:**
- Walking: < 5 km/h
- Cycling: 5-25 km/h
- Driving: 25-80 km/h
- Transit: > 80 km/h

### Emission Factors

- **Driving**: 0.21 kg CO₂/km (petrol car)
- **Walking**: 0.01 kg CO₂/km (minimal)
- **Cycling**: 0.01 kg CO₂/km (minimal)
- **Transit**: 0.08 kg CO₂/km (bus average)
- **Unknown**: 0.15 kg CO₂/km (default)

## 📱 User Flow

1. **Open Automated Tracking**
   - Tap circular arrow icon in Carbon Calculator

2. **Enable Location** (if not already)
   - Tap "Enable Location Access"
   - Grant permission in system dialog

3. **Choose Data Source:**
   - **Option A**: Import Google Takeout file
   - **Option B**: Start real-time tracking
   - **Option C**: Sign in with Google (for future API access)

4. **Review Data**
   - See total distance, trips, and emissions
   - View transport mode breakdown

5. **Apply to Calculator**
   - Tap "Apply to Calculator"
   - Activities automatically added to carbon footprint

## 🐛 Troubleshooting

### "Google Sign-In SDK not available"
- Ensure GoogleSignIn package is added
- Clean build folder (Cmd+Shift+K)
- Rebuild project

### "Configuration error: Google Client ID not configured"
- Add your Client ID to `Config.swift`
- Ensure it matches your Bundle ID in Google Cloud Console

### "File import failed"
- Ensure file is valid JSON from Google Takeout
- Check file permissions
- Try re-exporting from Google Takeout

### "Location permission denied"
- Go to Settings > Privacy > Location Services
- Enable for Greenify
- Choose "While Using App" or "Always"

### No trips detected
- Ensure location history is enabled in Google account
- Check date range (only today's trips are shown by default)
- Verify file format matches Google Takeout structure

## 🔒 Privacy & Security

- **Location data**: Processed locally, never sent to external servers
- **Google Sign-In**: Only requests necessary scopes
- **File access**: Uses secure scoped resources
- **User control**: Can revoke access at any time

## 📊 Data Processing

### Google Takeout File Structure
```json
{
  "timelineObjects": [
    {
      "activitySegment": {
        "startLocation": { "latitudeE7": ..., "longitudeE7": ... },
        "endLocation": { "latitudeE7": ..., "longitudeE7": ... },
        "duration": {
          "startTimestamp": "2024-01-17T08:00:00.000Z",
          "endTimestamp": "2024-01-17T08:30:00.000Z"
        },
        "activities": [
          { "activityType": "IN_VEHICLE" }
        ]
      }
    }
  ]
}
```

### Processing Steps
1. Parse JSON structure
2. Extract activity segments
3. Filter by date (today)
4. Calculate distances
5. Detect transport modes
6. Group into trips
7. Calculate emissions

## 🎯 Future Enhancements

- [ ] Google Maps Timeline API integration
- [ ] Historical data analysis
- [ ] Route visualization
- [ ] Export carbon footprint data
- [ ] Background location tracking
- [ ] Trip suggestions and optimization
- [ ] Integration with other Google services

## 📚 References

- [Google Sign-In for iOS](https://developers.google.com/identity/sign-in/ios)
- [Google Takeout](https://takeout.google.com/)
- [Core Location Framework](https://developer.apple.com/documentation/corelocation)
- [Location History Data Format](https://support.google.com/accounts/answer/3024190)
