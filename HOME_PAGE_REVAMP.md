# Home Page Revamp & Carbon Offset Events

## Overview

Completely revamped the home page with modern design and added comprehensive carbon offset events functionality with registration system.

## ✅ Features Implemented

### 1. **Revamped Home Page** 🏠

**New Design Elements:**
- ✅ Modern header with gradient icon
- ✅ Quick stats badges (carbon offset, events registered)
- ✅ Enhanced carbon footprint section
- ✅ New "Offset Your Carbon" events section
- ✅ Improved visual hierarchy and spacing
- ✅ Better typography and colors

**Sections:**
1. **Header** - Welcome message with quick stats
2. **Carbon Footprint** - Daily emissions with progress
3. **Quick Stats** - Weekly and monthly totals
4. **Carbon Offset Events** - Upcoming events (NEW!)
5. **Sustainability Rating** - Current rating
6. **Quick Actions** - Navigation shortcuts
7. **Daily Tips** - Sustainability tips

### 2. **Carbon Offset Events System** 🌱

**Event Types:**
- ✅ Tree Plantation
- ✅ Beach Cleanup
- ✅ Community Garden
- ✅ Renewable Energy
- ✅ Waste Reduction
- ✅ Education
- ✅ Conservation

**Event Features:**
- ✅ Event details (date, time, location)
- ✅ Participant limits and tracking
- ✅ Carbon offset per participant
- ✅ Requirements and benefits
- ✅ Registration deadline
- ✅ Status indicators (Open, Full, Closed)

### 3. **Event Registration System** 📝

**Registration Features:**
- ✅ Full registration form
- ✅ Name, email, phone validation
- ✅ Terms and conditions
- ✅ Success/error handling
- ✅ Haptic feedback
- ✅ Registration persistence
- ✅ Duplicate prevention

**Registration Flow:**
1. User views event details
2. Taps "Register for Event"
3. Fills registration form
4. Submits registration
5. Receives confirmation
6. Event count updates

### 4. **Event Details Page** 📋

**Features:**
- ✅ Hero section with event icon
- ✅ Complete event information
- ✅ Interactive map with location
- ✅ Requirements list
- ✅ Benefits list
- ✅ Registration button
- ✅ Status indicators

### 5. **All Events View** 📅

**Features:**
- ✅ Category filtering
- ✅ All upcoming events
- ✅ Search and filter
- ✅ Event cards with status
- ✅ Navigation to details

## File Structure

### New Files Created:
1. **Models/CarbonOffsetEvent.swift**
   - Event model with all properties
   - EventCategory enum
   - EventLocation struct
   - EventRegistration model
   - Mock data (6 events)

2. **ViewModels/CarbonOffsetEventsViewModel.swift**
   - Event management
   - Registration handling
   - Persistence (UserDefaults)
   - Carbon offset calculations

3. **Views/EventDetailView.swift**
   - Complete event details
   - Map integration
   - Registration button
   - Requirements and benefits

4. **Views/EventRegistrationView.swift**
   - Registration form
   - Validation
   - Success/error handling
   - Terms and conditions

### Modified Files:
1. **Views/HomeView.swift**
   - Revamped design
   - Added events section
   - Quick stats badges
   - AllEventsView integration

## Mock Data

### 6 Events Created:

1. **Community Tree Plantation Drive**
   - Date: 7 days from now
   - Participants: 67/100
   - Offset: 2.5 kg CO₂ per participant
   - Location: Central Park, Thane

2. **Beach Cleanup Initiative**
   - Date: 10 days from now
   - Participants: 89/150
   - Offset: 1.2 kg CO₂ per participant
   - Location: Juhu Beach, Mumbai

3. **Community Garden Workshop**
   - Date: 14 days from now
   - Participants: 32/50
   - Offset: 0.8 kg CO₂ per participant
   - Location: Community Garden Center

4. **Solar Panel Installation Workshop**
   - Date: 21 days from now
   - Participants: 18/30
   - Offset: 5.0 kg CO₂ per participant
   - Location: Community Center

5. **Zero Waste Workshop**
   - Date: 5 days from now
   - Participants: 25/40
   - Offset: 1.5 kg CO₂ per participant
   - Location: Eco Learning Center

6. **Climate Change Awareness Seminar**
   - Date: 12 days from now
   - Participants: 156/200
   - Offset: 0.5 kg CO₂ per participant
   - Location: City Hall Auditorium

## UI Components

### EventCardView
- Event icon with gradient background
- Event title and date
- Participant count and carbon offset
- Status badge (Open/Full/Closed)
- Navigation chevron

### EventDetailView
- Hero section with large icon
- Complete event information
- Interactive map
- Requirements checklist
- Benefits list
- Registration button with states

### EventRegistrationView
- Event summary card
- Registration form (name, email, phone)
- Terms and conditions
- Submit button with loading state
- Success/error alerts

### AllEventsView
- Category filter chips
- Scrollable event list
- Empty state handling
- Navigation to details

## Design Features

### Color Scheme
- **Green**: Primary action color, success states
- **Blue**: Information, stats
- **Red**: Errors, full events
- **Gray**: Disabled, closed events
- **Category Colors**: Each event type has unique color

### Typography
- **Headings**: Bold, rounded design font
- **Body**: Regular, readable sizes
- **Captions**: Smaller, secondary color
- **Numbers**: Large, bold for emphasis

### Spacing
- Consistent 16-24pt spacing
- Card padding: 18-20pt
- Section spacing: 24pt
- Component spacing: 12-16pt

### Visual Elements
- Gradient backgrounds
- Rounded corners (12-20pt)
- Shadows for depth
- Icons with SF Symbols
- Status badges
- Progress indicators

## User Flow

### Viewing Events:
```
Home → Carbon Offset Events Section
  → Tap "See All" → All Events View
    → Filter by category
    → Tap event → Event Details
      → View map, requirements, benefits
      → Tap "Register" → Registration Form
        → Fill details → Submit
          → Success → Back to Details
```

### Registration:
```
1. User browses events on home page
2. Taps event card or "See All"
3. Views event details
4. Taps "Register for Event"
5. Fills registration form
6. Submits registration
7. Receives confirmation
8. Event count updates
9. Total offset updates on home
```

## Data Persistence

### Storage:
- **Events**: In-memory (mock data)
- **Registrations**: UserDefaults (JSON)
- **Image Files**: Documents directory

### Registration Data:
```swift
struct EventRegistration {
    let id: UUID
    let eventId: UUID
    let participantName: String
    let participantEmail: String
    let participantPhone: String
    let registrationDate: Date
    let status: RegistrationStatus
}
```

## Carbon Offset Calculation

### Per Event:
- Each event has `carbonOffsetPerParticipant`
- Total offset = sum of all confirmed registrations
- Displayed on home page

### Example:
- Tree Plantation: 2.5 kg CO₂ per participant
- Beach Cleanup: 1.2 kg CO₂ per participant
- If user registers for both: 3.7 kg CO₂ total offset

## Status Indicators

### Event Status:
- **Open**: Green registration button, available spots
- **Full**: Red badge, registration disabled
- **Closed**: Gray badge, registration disabled
- **Deadline Passed**: Registration disabled

### Registration Status:
- **Pending**: Awaiting confirmation
- **Confirmed**: Active registration
- **Cancelled**: Registration cancelled

## Validation

### Registration Form:
- ✅ Name: Required, non-empty
- ✅ Email: Required, must contain "@"
- ✅ Phone: Required, non-empty
- ✅ All fields validated before submission

### Event Registration:
- ✅ Check if event is open
- ✅ Check if event is full
- ✅ Check registration deadline
- ✅ Prevent duplicate registrations (by email)

## Error Handling

### Registration Errors:
- Event not found
- Registration closed
- Event full
- Deadline passed
- Already registered
- Invalid form data

### User Feedback:
- Success alerts
- Error messages
- Haptic feedback
- Loading states
- Disabled states

## Future Enhancements

### Short-term:
- [ ] Email confirmation
- [ ] Calendar integration
- [ ] Push notifications
- [ ] Share event functionality
- [ ] Event reminders

### Medium-term:
- [ ] Server-side event management
- [ ] Real-time participant updates
- [ ] Event check-in system
- [ ] Photo uploads from events
- [ ] Event reviews/ratings

### Long-term:
- [ ] Event creation by users
- [ ] Community events
- [ ] Event series/recurring
- [ ] Leaderboards
- [ ] Badges and achievements

## Testing Checklist

### Home Page:
- [ ] Header displays correctly
- [ ] Quick stats show correct values
- [ ] Events section shows upcoming events
- [ ] Total offset calculates correctly
- [ ] Navigation to events works

### Event Details:
- [ ] All information displays correctly
- [ ] Map shows correct location
- [ ] Requirements and benefits listed
- [ ] Registration button states correct
- [ ] Navigation works

### Registration:
- [ ] Form validation works
- [ ] Success flow works
- [ ] Error handling works
- [ ] Duplicate prevention works
- [ ] Persistence works

### All Events:
- [ ] Category filtering works
- [ ] Event list displays correctly
- [ ] Empty state shows when no events
- [ ] Navigation to details works

## Summary

| Feature | Status | Details |
|---------|--------|---------|
| Home Page Revamp | ✅ | Modern design, better UX |
| Events System | ✅ | 6 mock events, 7 categories |
| Event Details | ✅ | Complete information, map |
| Registration | ✅ | Full form, validation |
| Persistence | ✅ | UserDefaults storage |
| Carbon Offset | ✅ | Tracking and display |
| UI Design | ✅ | Professional, polished |

**Result: Complete carbon offset events system with beautiful, modern design!** 🎉
