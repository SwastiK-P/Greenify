# Suggested Actions Feature

## Overview

The Carbon Calculator now includes a comprehensive **Suggested Actions** system that provides interactive buttons in chat messages to help users quickly log activities without typing everything manually. This makes the app more user-friendly and reduces friction in logging carbon footprint data.

## Features

### 1. **Route Selection** (Transport)
- **Trigger**: When user mentions driving/traveling between locations
- **Action**: Shows "Select Route" button
- **Functionality**: Opens route selection sheet with multiple route options
- **Example**: "I drove from Diva to Thane" → Shows route selection button

### 2. **Vehicle Selection** (Transport)
- **Trigger**: When user mentions driving but vehicle type is unclear
- **Action**: Shows "Select Vehicle Type" button
- **Functionality**: Opens vehicle selection sheet with all vehicle types
- **Options**: Car (Petrol/Diesel/Electric), Bus, Train, Motorcycle, Flight
- **Example**: "I drove to work" → Shows vehicle selection button

### 3. **Appliance Selection** (Electricity)
- **Trigger**: When user mentions electricity/energy usage
- **Action**: Shows "Select Appliance" button
- **Functionality**: Opens appliance selection sheet
- **Options**: AC, Water Heating, Home Electricity, Electronics, Refrigerator, Washing Machine
- **Example**: "I used electricity" → Shows appliance selection button

### 4. **Time Duration** (Electricity)
- **Trigger**: When AI asks about duration/time
- **Action**: Shows "Set Duration" button
- **Functionality**: Opens appliance selection (which includes duration)
- **Example**: "How long did you use it?" → Shows duration button

### 5. **Meal Type Selection** (Food)
- **Trigger**: When user mentions eating/food/meals
- **Action**: Shows "Select Meal Type" button
- **Functionality**: Opens meal selection sheet with portion slider
- **Options**: Beef, Chicken, Fish, Vegetables, Dairy, Rice
- **Example**: "I ate lunch" → Shows meal selection button

### 6. **Portion Size** (Food)
- **Trigger**: When AI asks about quantity/portion
- **Action**: Shows "Estimate Portion" button
- **Functionality**: Opens meal selection with portion size slider
- **Example**: "How much did you eat?" → Shows portion button

## Implementation Details

### Action Detection

The system automatically detects when to show suggested actions based on:
1. **User message content** - Keywords like "drove", "electricity", "ate", etc.
2. **AI response content** - Questions like "What appliance?", "How long?", etc.
3. **Context** - Missing information that needs user input

### Action Types

```swift
enum SuggestedActionType {
    case routeSelection
    case vehicleSelection
    case applianceSelection
    case mealTypeSelection
    case portionSize
    case timeDuration
    case wasteTypeSelection
    case waterUsageType
    case energySource
}
```

### UI Components

1. **SuggestedActionsView**: Container for displaying action buttons
2. **ActionButton**: Individual action button with icon and gradient
3. **Selection Views**: 
   - `VehicleSelectionView`
   - `ApplianceSelectionView`
   - `MealSelectionView`
   - `RouteSelectionView` (existing)

## Usage Examples

### Example 1: Vehicle Selection
```
User: "I drove to work"
AI: "What type of vehicle did you use?"
→ Shows: [Select Vehicle Type] button
User taps → Opens vehicle selection sheet
User selects: "Car (Electric)"
→ Logs activity with vehicle type
```

### Example 2: Appliance Selection
```
User: "I used electricity today"
AI: "Which appliance did you use?"
→ Shows: [Select Appliance] button
User taps → Opens appliance selection
User selects: "Air Conditioning" for 3 hours
→ Logs: AC - 3 hours = 2.1 kg CO₂
```

### Example 3: Meal Selection
```
User: "I had lunch"
AI: "What did you eat?"
→ Shows: [Select Meal Type] button
User taps → Opens meal selection
User selects: "Chicken" with 0.3 kg portion
→ Logs: Chicken - 0.3 kg = 2.07 kg CO₂
```

### Example 4: Route Selection (Existing)
```
User: "I drove from Diva to Thane"
→ Shows: [Select Route] button
User taps → Opens route selection
User selects: "Diva → Mumbra → Thane"
→ Logs: Car (Petrol) - 15.2 km = 3.19 kg CO₂
```

## Benefits

1. **Reduced Typing**: Users don't need to type everything
2. **Faster Logging**: Quick selection instead of back-and-forth chat
3. **Better UX**: Visual selection is more intuitive
4. **Accurate Data**: Predefined options ensure correct activity types
5. **Consistent**: Same interface pattern across all activity types

## Future Enhancements

### Planned Actions:
1. **Waste Type Selection**: For waste activities
2. **Water Usage Type**: For water consumption
3. **Energy Source Selection**: Renewable vs non-renewable
4. **Quick Actions**: One-tap common activities
5. **Smart Suggestions**: Based on user history
6. **Location-based**: Suggest activities based on location

### Advanced Features:
- **Voice Selection**: Voice commands for actions
- **Siri Shortcuts**: Integration with Siri
- **Widget Actions**: Quick actions from home screen
- **Notification Actions**: Quick log from notifications

## Code Structure

```
Greenify/
├── Models/
│   └── SuggestedAction.swift          # Action models
├── Views/
│   ├── SuggestedActionsView.swift     # Action buttons UI
│   ├── VehicleSelectionView.swift      # Vehicle selection
│   ├── ApplianceSelectionView.swift    # Appliance selection
│   └── MealSelectionView.swift          # Meal selection
└── ViewModels/
    └── CarbonCalculatorViewModel.swift # Action detection & handlers
```

## Technical Notes

- Actions are stored in `ChatMessage.suggestedActions`
- Actions are detected automatically in `detectSuggestedActions()`
- Actions are handled in `handleSuggestedAction()`
- Each action type has its own selection view
- Actions can be reopened if dismissed (like route selection)

## Testing

To test suggested actions:
1. Type: "I drove to work" → Should show vehicle selection
2. Type: "I used electricity" → Should show appliance selection
3. Type: "I had dinner" → Should show meal selection
4. Type: "I drove from X to Y" → Should show route selection

All actions should open their respective selection sheets and log activities correctly.
