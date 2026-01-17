# Route Detection and Selection Feature

## Overview

The Carbon Calculator now supports intelligent route detection and selection using MapKit. When users mention driving or traveling between locations, the app automatically detects the route, finds multiple route options, and allows users to select their preferred route.

## Features

### 1. **Automatic Route Detection**
- Detects route information from natural language input
- Examples:
  - "I drove from Diva to Thane"
  - "I traveled from Mumbai to Pune"
  - "Drove from home to office"

### 2. **Multiple Route Options**
- Uses MapKit's `MKDirections` API to find multiple routes
- Shows routes sorted by distance (shortest first)
- Displays route name, distance, and estimated duration

### 3. **Route Selection UI**
- Beautiful card-based interface showing all available routes
- Each route shows:
  - Route name (e.g., "Diva → Mumbra → Thane")
  - Distance in km
  - Estimated travel time
  - Route preview with major waypoints

### 4. **Automatic Activity Logging**
- Once a route is selected, the activity is automatically logged
- Calculates carbon emissions based on:
  - Vehicle type (detected from user input)
  - Route distance
  - Vehicle-specific emission factors

### 5. **Route Information in History**
- Activities with routes show:
  - Route name in activity display
  - From/To locations
  - Distance and duration
  - Full route details in breakdown view

## Implementation Details

### Route Detection Patterns

The system recognizes various patterns:
- "drove from X to Y"
- "drive from X to Y"
- "traveled from X to Y"
- "went from X to Y"
- "X to Y" (simpler form)

### Vehicle Type Detection

Automatically detects vehicle type from user input:
- **Car (Petrol)**: "car", "drove", "driving" (default)
- **Car (Electric)**: "electric car", "ev"
- **Car (Diesel)**: "diesel car"
- **Bus**: "bus", "took bus", "by bus"
- **Train**: "train", "took train", "by train"
- **Motorcycle**: "motorcycle", "bike", "scooter"
- **Flight**: "flight", "flew", "airplane"

### Route Service (`RouteService.swift`)

- **Geocoding**: Converts location names to coordinates
- **Route Calculation**: Uses MapKit to find multiple routes
- **Route Naming**: Generates descriptive route names with waypoints
- **Error Handling**: Handles geocoding failures and route not found scenarios

### Data Models

#### `RouteInfo`
```swift
struct RouteInfo: Codable {
    let routeName: String
    let from: String
    let to: String
    let distance: Double // km
    let duration: Double // minutes
    let waypoints: [String]
}
```

#### `Route`
```swift
struct Route: Identifiable {
    let id: UUID
    let name: String
    let distance: Double
    let duration: Double
    let polyline: MKPolyline
    let steps: [RouteStep]
}
```

## Usage Examples

### Example 1: Basic Route
**User Input**: "I drove from Diva to Thane"

**System Response**:
1. Detects route: Diva → Thane
2. Finds routes: 
   - "Diva → Mumbra → Thane" (15.2 km, 25 min)
   - "Diva → Vashi → Thane" (18.5 km, 30 min)
3. User selects route
4. Activity logged: "Car (Petrol) - Diva → Mumbra → Thane - 15.2 km = 3.19 kg CO₂"

### Example 2: With Vehicle Type
**User Input**: "I took a bus from Mumbai to Pune"

**System Response**:
1. Detects: Bus from Mumbai to Pune
2. Finds routes with bus-appropriate paths
3. Logs with bus emission factor (0.08 kg CO₂/km)

### Example 3: Electric Vehicle
**User Input**: "Drove my electric car from home to office"

**System Response**:
1. Detects: Electric car route
2. Uses lower emission factor (0.05 kg CO₂/km)
3. Logs with appropriate emissions

## UI Components

### RouteSelectionView
- Modal sheet that appears when route is detected
- Shows header with from/to locations
- Lists all available routes
- Allows selection and confirmation

### RouteCardView
- Individual route card with:
  - Route number badge
  - Route name
  - Distance and duration
  - Route preview
  - Selection indicator

### Enhanced Activity Display
- Shows route information in activity list
- Displays route name, distance, and duration
- Color-coded route information

## Future Enhancements

1. **Map Visualization**: Show routes on an interactive map
2. **Route Comparison**: Compare emissions across different routes
3. **Frequent Routes**: Save and quick-select frequently used routes
4. **Public Transport Routes**: Specific route finding for buses/trains
5. **Multi-Modal Routes**: Routes combining multiple transport types
6. **Route History**: View past routes and their emissions
7. **Route Sharing**: Share route and emissions data
8. **Offline Support**: Cache routes for offline access

## Technical Requirements

### MapKit Framework
- Requires `MapKit` framework
- Uses `MKDirections` for route calculation
- Uses `CLGeocoder` for location geocoding

### Permissions
- No special permissions required (uses network for geocoding and routing)

### Network Requirements
- Requires internet connection for:
  - Geocoding location names
  - Calculating routes via MapKit

## Error Handling

The system handles:
- **Location Not Found**: Shows error if location cannot be geocoded
- **No Routes Found**: Informs user if no routes exist between locations
- **Network Errors**: Gracefully handles network failures
- **Invalid Input**: Validates location names before processing

## Carbon Emission Calculation

Emissions are calculated using:
```
Emissions = Distance (km) × Emission Factor (kg CO₂/km)
```

Emission factors by vehicle type:
- Car (Petrol): 0.21 kg CO₂/km
- Car (Diesel): 0.17 kg CO₂/km
- Car (Electric): 0.05 kg CO₂/km
- Bus: 0.08 kg CO₂/km
- Train: 0.04 kg CO₂/km
- Motorcycle: 0.11 kg CO₂/km
- Flight (Domestic): 0.25 kg CO₂/km

## Testing

To test the feature:
1. Open Carbon Calculator
2. Type: "I drove from Diva to Thane"
3. Wait for route detection
4. Select a route from the list
5. Confirm and see the activity logged
6. Check the breakdown view to see route details

## Code Structure

```
Greenify/
├── ViewModels/
│   ├── RouteService.swift          # Route detection and calculation
│   └── CarbonCalculatorViewModel.swift  # Route integration
├── Views/
│   ├── RouteSelectionView.swift   # Route selection UI
│   └── CarbonCalculatorView.swift  # Main calculator view
└── Models/
    └── CarbonFootprint.swift       # Activity and RouteInfo models
```
