# Chat-Based Carbon Calculator

The Carbon Calculator has been redesigned as a conversational, iMessage-style interface powered by Google's Gemini AI.

## What's New

### 🎨 Chat Interface
- **iMessage-style bubbles**: User messages appear on the right (green), AI responses on the left (gray)
- **Real-time typing indicator**: Shows when AI is processing
- **Auto-scrolling**: Chat automatically scrolls to latest messages
- **Results summary bar**: Shows daily emissions at the top when available

### 🤖 AI-Powered Logging
- **Natural language input**: Users can say things like "I drove to work" instead of filling forms
- **Intelligent follow-up questions**: AI asks clarifying questions (distance, car type, etc.)
- **Automatic calculation**: Once all details are gathered, AI calculates and logs the carbon footprint
- **Conversational flow**: Feels like chatting with a friend

## How It Works

1. **User sends a message**: "I drove to work"
2. **AI asks follow-up**: "From where to where? What's the distance?"
3. **User responds**: "From home to office, about 15 km"
4. **AI asks more**: "Is your car electric, petrol, or diesel?"
5. **User responds**: "Petrol"
6. **AI calculates and logs**: Automatically calculates emissions and adds to the log

## Files Created/Modified

### New Files
- `Greenify/Models/ChatMessage.swift` - Chat message model
- `Greenify/ViewModels/GeminiService.swift` - Gemini AI integration service
- `Greenify/Config.swift` - API key configuration
- `GEMINI_API_SETUP.md` - Detailed API setup instructions

### Modified Files
- `Greenify/Views/CarbonCalculatorView.swift` - Completely redesigned as chat interface
- `Greenify/ViewModels/CarbonCalculatorViewModel.swift` - Added chat functionality
- `Greenify/Models/CarbonFootprint.swift` - Added Electric car support and improved initializer

## Setup Instructions

### 1. Get Gemini API Key
Visit: https://makersuite.google.com/app/apikey

### 2. Add API Key
Open `Greenify/Config.swift` and replace the empty string:

```swift
static let geminiAPIKey = "YOUR_API_KEY_HERE"
```

**Location**: `/Users/swastik/Developer/Greenify/Greenify/Config.swift`

### 3. Build and Run
The app is ready to use! Navigate to the Carbon Calculator tab and start chatting.

## Features

### Chat Features
- ✅ iMessage-style message bubbles
- ✅ Typing indicators
- ✅ Auto-scroll to latest message
- ✅ Timestamp display
- ✅ Error handling with user-friendly messages

### AI Features
- ✅ Natural language understanding
- ✅ Context-aware follow-up questions
- ✅ Automatic data extraction
- ✅ Carbon footprint calculation
- ✅ Activity logging

### Existing Features (Preserved)
- ✅ View detailed results
- ✅ Emission breakdown by category
- ✅ Time period projections (weekly, monthly, yearly)
- ✅ Sustainability rating
- ✅ Recommendations

## Example Conversations

**Transport:**
```
User: I drove to work
AI: From where to where? What's the distance?
User: From home to office, 20 km
AI: Is your car electric, petrol, or diesel?
User: Petrol
AI: ✅ Logged: Car (Petrol) - 20.0 km = 4.20 kg CO₂
```

**Food:**
```
User: I ate beef for dinner
AI: How much beef did you consume? (in kg or approximate portion)
User: About 0.3 kg
AI: ✅ Logged: Beef - 0.3 kg = 8.10 kg CO₂
```

**Electricity:**
```
User: I used air conditioning for 3 hours
AI: ✅ Logged: Air Conditioning - 3.0 hours = 2.10 kg CO₂
```

## Technical Details

### Architecture
- **MVVM Pattern**: Maintained throughout
- **Async/Await**: Modern Swift concurrency for API calls
- **Combine**: Reactive state management
- **Protocol-Oriented**: Clean separation of concerns

### API Integration
- Uses Gemini Pro model via REST API
- Handles rate limiting and errors gracefully
- Extracts structured data from natural language
- Maintains conversation context

### Data Flow
1. User sends message → ViewModel
2. ViewModel → GeminiService (API call)
3. GeminiService → Parse response
4. Extract activity data (if complete)
5. Update activities array
6. Recalculate carbon footprint
7. Update UI

## Troubleshooting

**"API key is missing"**
- Check `Config.swift` has your API key
- Ensure no extra spaces or quotes

**"Invalid response from API"**
- Check internet connection
- Verify API key is valid
- Check API quota/limits

**AI not asking follow-up questions**
- This is normal - AI may extract all info from one message
- Try being more specific if needed

## Future Enhancements

Potential improvements:
- Voice input support
- Quick action buttons for common activities
- Chat history persistence
- Multiple conversation threads
- Export chat logs
- Integration with calendar for automatic logging
