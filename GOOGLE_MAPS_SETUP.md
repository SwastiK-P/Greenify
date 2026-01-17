# Google Maps Platform & Sign-In Setup Guide

Complete step-by-step guide to set up Google Maps Platform and Google Sign-In for location history tracking.

## 📋 Prerequisites

- Google account
- Apple Developer account (for iOS app)
- Xcode installed

## 🚀 Step-by-Step Setup

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click **"Select a project"** dropdown at the top
3. Click **"New Project"**
4. Enter project name: `Greenify` (or your preferred name)
5. Click **"Create"**
6. Wait for project creation (usually a few seconds)
7. Select your newly created project

### Step 2: Enable Required APIs

1. In Google Cloud Console, go to **"APIs & Services" > "Library"**
2. Search for and enable these APIs:
   - **Google Sign-In API** (or Identity Platform)
   - **Maps SDK for iOS** (if using maps)
   - **Places API** (optional, for location details)
   - **Directions API** (optional, for route information)
   - **Geocoding API** (optional, for address conversion)

3. For each API:
   - Click on the API name
   - Click **"Enable"** button
   - Wait for activation

### Step 3: Create OAuth 2.0 Credentials

1. Go to **"APIs & Services" > "Credentials"**
2. Click **"+ CREATE CREDENTIALS"** at the top
3. Select **"OAuth client ID"**

#### First Time Setup (OAuth Consent Screen):
   - If prompted, click **"Configure Consent Screen"**
   - Choose **"External"** (unless you have Google Workspace)
   - Click **"Create"**
   - Fill in the form:
     - **App name**: `Greenify`
     - **User support email**: Your email
     - **Developer contact information**: Your email
   - Click **"Save and Continue"**
   - On **Scopes** page, click **"Save and Continue"** (default scopes are fine)
   - On **Test users** page, click **"Save and Continue"** (add test users if needed)
   - Click **"Back to Dashboard"**

#### Create iOS OAuth Client:
4. Back in Credentials page, click **"+ CREATE CREDENTIALS" > "OAuth client ID"**
5. Select **"iOS"** as application type
6. Fill in:
   - **Name**: `Greenify iOS`
   - **Bundle ID**: `com.swastik.Greenify` (must match your Xcode Bundle Identifier exactly)
7. Click **"Create"**
8. **IMPORTANT**: Copy the **Client ID** (looks like: `123456789-abcdefghijklmnop.apps.googleusercontent.com`)
   - Save this somewhere safe - you'll need it in Step 5

### Step 4: Create API Key (for Maps Platform)

1. Still in **"APIs & Services" > "Credentials"**
2. Click **"+ CREATE CREDENTIALS" > "API key"**
3. Copy the API key (looks like: `AIzaSy...`)
4. Click **"Restrict key"** (recommended for security)
5. Under **"Application restrictions"**:
   - Select **"iOS apps"**
   - Click **"Add an item"**
   - Enter your Bundle ID: `com.swastik.Greenify`
6. Under **"API restrictions"**:
   - Select **"Restrict key"**
   - Check these APIs:
     - Maps SDK for iOS
     - Places API (if enabled)
     - Directions API (if enabled)
     - Geocoding API (if enabled)
7. Click **"Save"**
8. **IMPORTANT**: Copy the **API Key** - you'll need it in Step 5

### Step 5: Configure Xcode Project

#### 5.1 Add Google Sign-In SDK

1. Open your project in Xcode
2. Go to **File > Add Package Dependencies...**
3. In the search bar, enter: `https://github.com/google/GoogleSignIn-iOS`
4. Click **"Add Package"**
5. Select **"GoogleSignIn"** product
6. Click **"Add Package"**

#### 5.2 Add Google Maps SDK (Optional - if using maps)

1. Go to **File > Add Package Dependencies...**
2. Enter: `https://github.com/googlemaps/ios-maps-sdk`
3. Click **"Add Package"**
4. Select **"GoogleMaps"** and **"GoogleMapsUtils"** (if needed)
5. Click **"Add Package"**

#### 5.3 Update Config.swift

Open `Greenify/Config.swift` and update:

```swift
struct Config {
    // ... existing Gemini API key ...
    
    // MARK: - Google Maps Platform Configuration
    
    // OAuth 2.0 Client ID (from Step 3)
    static let googleClientID = "YOUR_CLIENT_ID_HERE.apps.googleusercontent.com"
    
    // Google Maps API Key (from Step 4)
    static let googleMapsAPIKey = "YOUR_API_KEY_HERE"
}
```

Replace:
- `YOUR_CLIENT_ID_HERE` with your OAuth Client ID
- `YOUR_API_KEY_HERE` with your API Key

#### 5.4 Configure URL Scheme

1. In Xcode, select your project in the navigator
2. Select the **Greenify** target
3. Go to **"Info"** tab
4. Expand **"URL Types"** section
5. Click **"+"** to add a new URL Type
6. Fill in:
   - **Identifier**: `GoogleSignIn`
   - **URL Schemes**: Your **reversed Client ID**
     - Example: If Client ID is `123456789-abc.apps.googleusercontent.com`
     - URL Scheme should be: `com.googleusercontent.apps.123456789-abc`
     - (Reverse the Client ID and remove `.apps.googleusercontent.com`)

#### 5.5 Update Info.plist (if needed)

The location permissions are already configured. Verify these keys exist in your project settings:

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription` (for background tracking)

### Step 6: Initialize Google Services

The code is already set up! Just ensure:

1. Google Sign-In is initialized in `GoogleLocationService.swift`
2. The Client ID from Config is used
3. URL scheme matches your reversed Client ID

### Step 7: Test the Setup

1. Build and run your app in Xcode
2. Navigate to Automated Tracking
3. Tap **"Sign in with Google"**
4. You should see Google Sign-In screen
5. Select your Google account
6. Grant permissions if prompted
7. You should be signed in successfully

## 🔐 Security Best Practices

### API Key Restrictions
- ✅ Always restrict API keys to specific apps
- ✅ Limit API keys to only needed APIs
- ✅ Use different keys for development and production
- ❌ Never commit API keys to version control

### OAuth Client Security
- ✅ Use separate OAuth clients for development and production
- ✅ Regularly review OAuth consent screen
- ✅ Monitor API usage in Google Cloud Console

### Code Security
- ✅ Store keys in `Config.swift` (add to `.gitignore` if needed)
- ✅ Consider using environment variables for production
- ✅ Use Keychain for storing access tokens (already implemented)

## 🐛 Troubleshooting

### "Configuration error: Google Client ID not configured"
- ✅ Check `Config.swift` has the correct Client ID
- ✅ Ensure no extra spaces or quotes
- ✅ Verify Bundle ID matches Google Cloud Console

### "Sign in failed"
- ✅ Check URL scheme is correctly configured
- ✅ Verify Bundle ID matches exactly (case-sensitive)
- ✅ Ensure OAuth client is for iOS type
- ✅ Check OAuth consent screen is configured

### "API key invalid"
- ✅ Verify API key is correct in `Config.swift`
- ✅ Check API restrictions allow your Bundle ID
- ✅ Ensure required APIs are enabled
- ✅ Verify API key hasn't expired

### "Location permission denied"
- ✅ Go to Settings > Privacy > Location Services
- ✅ Enable location for Greenify
- ✅ Choose "While Using App" or "Always"

## 📱 Testing Checklist

- [ ] Google Sign-In SDK added via SPM
- [ ] Client ID added to Config.swift
- [ ] API Key added to Config.swift
- [ ] URL scheme configured correctly
- [ ] Bundle ID matches in Xcode and Google Cloud
- [ ] Required APIs enabled in Google Cloud
- [ ] OAuth consent screen configured
- [ ] Location permissions granted
- [ ] Sign-in flow works
- [ ] Location tracking works

## 📚 Additional Resources

- [Google Sign-In for iOS Documentation](https://developers.google.com/identity/sign-in/ios)
- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation/ios-sdk)
- [OAuth 2.0 Setup Guide](https://developers.google.com/identity/protocols/oauth2)
- [Google Cloud Console](https://console.cloud.google.com/)

## 🎯 Next Steps

After setup is complete:
1. Test Google Sign-In flow
2. Test location history import
3. Test real-time tracking
4. Verify carbon footprint calculations
5. Test on physical device (recommended)

## 💡 Pro Tips

1. **Development vs Production**: Create separate OAuth clients and API keys for development and production
2. **API Quotas**: Monitor your API usage in Google Cloud Console to avoid unexpected charges
3. **Testing**: Use test users in OAuth consent screen during development
4. **Error Handling**: The app includes comprehensive error handling - check error messages for specific issues
