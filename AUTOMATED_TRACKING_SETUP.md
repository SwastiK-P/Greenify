# Automated Activity Tracking Setup

This document explains how to set up automated activity tracking using HealthKit and other services.

## Features Implemented

### ✅ HealthKit Integration
- Automatic tracking of steps, walking distance, cycling distance, and active energy
- One-tap authorization and data fetching
- Apply tracked data directly to carbon calculator

## Xcode Setup Required

### 1. Enable HealthKit Capability (REQUIRED)

**Important:** The entitlements file has been created, but you MUST enable HealthKit in Xcode for it to work:

1. Open your project in Xcode
2. Select the **Greenify** target in the project navigator
3. Go to the **Signing & Capabilities** tab
4. Click the **+ Capability** button (top left of the capabilities list)
5. Search for and double-click **HealthKit** to add it
6. Xcode will automatically configure the entitlement with your Apple Developer account
7. Ensure the **HealthKit** capability appears in the list with a checkmark

**Note:** If you see an error about the entitlement, make sure:
- You're signed in with your Apple Developer account in Xcode (Preferences > Accounts)
- Your app's Bundle Identifier is registered in your Apple Developer account
- You have the necessary permissions in your developer account

### 2. Verify Info.plist

The `Info.plist` file has been created with the required HealthKit usage descriptions:
- `NSHealthShareUsageDescription`: Explains why the app needs to read health data
- `NSHealthUpdateUsageDescription`: Explains why the app needs to update health data

If the Info.plist is not automatically included in your project:
1. In Xcode, right-click on the **Greenify** folder
2. Select **Add Files to "Greenify"...**
3. Select `Info.plist`
4. Ensure "Copy items if needed" is checked
5. Click **Add**

### 3. Build and Run

After enabling HealthKit capability:
1. Clean build folder (Cmd+Shift+K)
2. Build the project (Cmd+B)
3. Run on a physical device or simulator (HealthKit works on both, but real data is only available on physical devices)

## How to Use

1. **Open Automated Tracking**:
   - Navigate to the Carbon Calculator tab
   - Tap the circular arrow icon (🔄) in the top-left toolbar

2. **Authorize HealthKit**:
   - Tap "Authorize HealthKit" button
   - Grant permissions in the system dialog

3. **Fetch Data**:
   - Tap "Fetch Today's Data" to retrieve today's activity
   - View steps, walking distance, cycling distance, and active energy

4. **Apply to Calculator**:
   - Tap "Apply to Calculator" to automatically add walking/cycling activities
   - The carbon footprint will be recalculated automatically

## Data Sources

### Currently Available
- **Apple Health (HealthKit)**: Steps, walking, cycling, active energy

### Coming Soon
- Google Location History
- Banking Integration
- Smart Home Integration

## Technical Details

### HealthKit Data Types
- `HKQuantityTypeIdentifierStepCount`: Total steps
- `HKQuantityTypeIdentifierDistanceWalkingRunning`: Walking/running distance
- `HKQuantityTypeIdentifierDistanceCycling`: Cycling distance
- `HKQuantityTypeIdentifierActiveEnergyBurned`: Active energy burned

### Emission Factors
- **Walking**: 0.01 kg CO₂ per km (minimal, based on food energy)
- **Cycling**: 0.01 kg CO₂ per km (minimal, based on food energy)

These are very low compared to motorized transport, encouraging active transportation.

## Privacy

- All HealthKit data is processed locally on the device
- No health data is sent to external servers
- Users must explicitly authorize access
- Users can revoke access at any time in Settings > Privacy & Security > Health

## Troubleshooting

### "HealthKit Not Available"
- Ensure you're running on iOS (not macOS)
- HealthKit requires iOS 8.0 or later

### "Authorization Failed"
- Check that HealthKit capability is enabled in Xcode
- Verify Info.plist contains usage descriptions
- Try deleting and reinstalling the app

### "No Data Available"
- Ensure you have activity data in the Health app
- Try walking or cycling with your iPhone/Apple Watch
- Check that HealthKit permissions are granted

### Data Not Appearing in Calculator
- Ensure you tapped "Apply to Calculator" after fetching data
- Check that walking/cycling distances are greater than 0
- Verify the calculator view model is properly connected

## Future Enhancements

- Background data sync
- Historical data import
- Google Fit integration (for Android users)
- Location-based commute detection
- Calendar integration for scheduled trips
- Banking integration for purchase tracking
