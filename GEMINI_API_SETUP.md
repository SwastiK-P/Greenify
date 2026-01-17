# Gemini API Setup Guide

This app uses Google's Gemini AI to power the conversational carbon footprint calculator. Follow these steps to set up your API key:

## Step 1: Get Your Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey) or [Google Cloud Console](https://console.cloud.google.com/)
2. Sign in with your Google account
3. Navigate to "Get API Key" or create a new project
4. Copy your API key

## Step 2: Add API Key to the App

1. Open `Greenify/Config.swift` in Xcode
2. Find the line: `static let geminiAPIKey = ""`
3. Replace the empty string with your API key:
   ```swift
   static let geminiAPIKey = "YOUR_API_KEY_HERE"
   ```

## Step 3: Security Best Practices

For production apps, consider:

1. **Environment Variables**: Store the key in environment variables
   ```swift
   static let geminiAPIKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
   ```

2. **Keychain Storage**: Store sensitive keys in iOS Keychain
3. **Build Configuration**: Use different keys for Debug vs Release builds
4. **Never commit API keys** to version control - add `Config.swift` to `.gitignore` if it contains your key

## Example Config.swift

```swift
struct Config {
    // Get your API key from: https://makersuite.google.com/app/apikey
    static let geminiAPIKey = "YOUR_API_KEY_HERE"
}
```

## Testing

After adding your API key:
1. Build and run the app
2. Navigate to the Carbon Calculator tab
3. Try sending a message like "I drove to work"
4. The AI should respond and ask follow-up questions

## Troubleshooting

- **"API key is missing" error**: Make sure you've added your key to `Config.swift`
- **"Invalid response" error**: Check your internet connection and API key validity
- **Rate limiting**: Free tier has rate limits. Consider upgrading if you hit limits

## API Usage

The app uses the Gemini Pro model via REST API. Each conversation message counts toward your API quota. Monitor your usage in the Google Cloud Console.
