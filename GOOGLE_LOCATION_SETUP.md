# Google Location History Integration Setup

This document explains the Google Location History integration for automated activity tracking.

## Current Implementation Status

### ✅ Completed
- Removed HealthKit integration
- Created Google Location History service structure
- Updated UI for Google Location History
- Location permission handling
- Data models for location trips and transport modes

### 🔧 Needs Implementation
- Google Sign-In SDK integration
- Google Location History API integration
- Location data parsing from Google Takeout or Timeline API

## How It Works

The Google Location History integration allows users to:
1. Sign in with their Google account
2. Fetch their location history data
3. Automatically detect travel routes and transportation modes
4. Calculate carbon footprint based on detected trips

## Implementation Options

### Option 1: Google Takeout API (Recommended for Initial Implementation)
- Users export their location history from Google Takeout
- App parses the exported JSON file
- Extract trips, distances, and transport modes
- Calculate emissions

**Pros:**
- No API key required initially
- Users have full control over their data
- Works offline after export

**Cons:**
- Requires manual export from user
- Not real-time

### Option 2: Google Maps Timeline API
- Direct API access to location history
- Real-time data fetching
- Requires Google Cloud project and API key

**Pros:**
- Real-time data
- Automated fetching
- Better user experience

**Cons:**
- Requires Google Cloud setup
- API key management
- More complex implementation

### Option 3: Google Fit API (Alternative)
- Access to activity data including location
- Better for fitness/activity tracking
- Can complement location history

## Required Setup

### 1. Google Sign-In SDK

Add Google Sign-In SDK to your project:

**Using Swift Package Manager:**
1. In Xcode: File > Add Package Dependencies
2. Add: `https://github.com/google/GoogleSignIn-iOS`
3. Import in your code: `import GoogleSignIn`

**Using CocoaPods:**
```ruby
pod 'GoogleSignIn'
```

### 2. Google Cloud Project Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable the following APIs:
   - Google Sign-In API
   - Google Maps Platform (if using Timeline API)
   - Location History API (if available)

### 3. Configure OAuth 2.0

1. In Google Cloud Console, go to **APIs & Services > Credentials**
2. Create OAuth 2.0 Client ID for iOS
3. Add your app's Bundle ID
4. Download the configuration file or note the Client ID

### 4. Update GoogleLocationService

Replace the placeholder `signInWithGoogle()` method with actual Google Sign-In implementation:

```swift
import GoogleSignIn

func signInWithGoogle() async throws {
    guard let presentingViewController = await UIApplication.shared.windows.first?.rootViewController else {
        throw GoogleLocationError.notSignedIn
    }
    
    let config = GIDConfiguration(clientID: "YOUR_CLIENT_ID")
    GIDSignIn.sharedInstance.configuration = config
    
    let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
    
    guard let accessToken = result.user.accessToken.tokenString else {
        throw GoogleLocationError.noAccessToken
    }
    
    self.accessToken = accessToken
    self.isSignedIn = true
}
```

### 5. Location History API Integration

For **Google Takeout** approach:
- Implement file picker to select exported JSON
- Parse `Location History.json` file
- Extract timeline objects and convert to trips

For **Timeline API** approach:
- Use access token to make API calls
- Fetch location history for date range
- Parse response and extract trips

## Data Structure

The service processes location data into:
- **LocationTrip**: Individual trip with start/end, distance, transport mode
- **TransportMode**: Enum (driving, walking, cycling, transit)
- **TransportActivity**: Processed activity with emissions calculation

## Transport Mode Detection

The service attempts to detect transport modes from location data:
- **Driving**: High speed, consistent movement
- **Walking**: Low speed, short distances
- **Cycling**: Medium speed, consistent movement
- **Transit**: Multiple stops, public transport patterns
- **Unknown**: Default fallback

## Emission Factors

Current emission factors (kg CO₂ per km):
- Driving: 0.21 (petrol car average)
- Walking: 0.01 (minimal, food energy)
- Cycling: 0.01 (minimal, food energy)
- Transit: 0.08 (bus average)
- Unknown: 0.15 (default assumption)

## Usage Flow

1. User opens Automated Tracking
2. Grants location permission (if not already)
3. Signs in with Google account
4. Fetches location history for today (or date range)
5. Service processes data and detects transport modes
6. User reviews detected trips and emissions
7. Applies data to carbon calculator

## Privacy Considerations

- All location data processing happens locally
- Google Sign-In only provides access token
- No location data sent to external servers (except Google's APIs)
- Users can revoke access at any time
- Clear privacy policy required for App Store

## Testing

### Test with Sample Data
1. Export sample location history from Google Takeout
2. Use test JSON file in development
3. Verify trip detection and emission calculations

### Test with Real Account
1. Use test Google account with location history
2. Test sign-in flow
3. Test data fetching and processing
4. Verify UI updates correctly

## Future Enhancements

- Background location tracking (with user permission)
- Real-time trip detection
- Route optimization suggestions
- Integration with Google Maps for route details
- Historical data analysis and trends
- Export carbon footprint data

## Troubleshooting

### "Not Signed In" Error
- Verify Google Sign-In SDK is properly integrated
- Check OAuth client ID is correct
- Ensure bundle ID matches Google Cloud configuration

### "No Location Data" Error
- Verify user has location history enabled in Google account
- Check date range for data availability
- Ensure proper API permissions

### Location Permission Denied
- Guide user to Settings > Privacy > Location Services
- Explain why location access is needed
- Provide clear usage description

## References

- [Google Sign-In for iOS](https://developers.google.com/identity/sign-in/ios)
- [Google Takeout API](https://takeout.google.com/settings/takeout)
- [Google Maps Platform](https://developers.google.com/maps)
- [Location History Data Format](https://support.google.com/accounts/answer/3024190)
