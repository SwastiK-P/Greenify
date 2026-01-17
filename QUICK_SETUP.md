# Quick Setup Reference - Google Maps Platform

## 🚀 Quick Start (5 Steps)

### 1. Google Cloud Console Setup
```
1. Go to: https://console.cloud.google.com/
2. Create new project: "Greenify"
3. Enable APIs:
   - Google Sign-In API
   - Maps SDK for iOS
4. Create OAuth Client ID (iOS):
   - Bundle ID: com.swastik.Greenify
   - Copy Client ID
5. Create API Key:
   - Restrict to iOS app
   - Restrict to Maps APIs
   - Copy API Key
```

### 2. Add SDKs in Xcode
```
File > Add Package Dependencies
1. https://github.com/google/GoogleSignIn-iOS
2. https://github.com/googlemaps/ios-maps-sdk (optional)
```

### 3. Update Config.swift
```swift
static let googleClientID = "YOUR_CLIENT_ID_HERE"
static let googleMapsAPIKey = "YOUR_API_KEY_HERE"
```

### 4. Configure URL Scheme
```
Info Tab > URL Types > +
Identifier: GoogleSignIn
URL Schemes: com.googleusercontent.apps.YOUR_CLIENT_ID_PREFIX
```

### 5. Test
```
Build & Run
Navigate to Automated Tracking
Tap "Sign in with Google"
```

## 📝 Detailed Steps

See `GOOGLE_MAPS_SETUP.md` for complete instructions.

## ✅ Checklist

- [ ] Google Cloud project created
- [ ] APIs enabled
- [ ] OAuth Client ID created
- [ ] API Key created
- [ ] SDKs added to Xcode
- [ ] Config.swift updated
- [ ] URL scheme configured
- [ ] App tested
