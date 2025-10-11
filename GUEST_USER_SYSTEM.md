# Guest User ID System

## Overview
This document explains the new guest user identification system that assigns unique IDs to users who join via the guest login option.

## Features Implemented

### 1. **Unique Guest ID Generation**
- Each guest user receives a unique ID in the format: `GUEST-XXXX` (e.g., `GUEST-0001`, `GUEST-0002`)
- IDs are automatically generated when a user signs in anonymously
- The system counts existing guest users and increments the number
- If a conflict occurs (rare), it falls back to timestamp-based ID generation

### 2. **Display Name Update**
- Guest users now display their unique guest ID instead of generic "Welcome Guest"
- Example: **"بەخێرهاتنەوە، GUEST-0001!"** instead of **"بەخێرهاتنەوە، میوان!"**

### 3. **Admin User Management**

#### User List View
- Guest IDs are displayed alongside user information in the admin user list
- Shows a blue badge with person icon and guest ID for easy identification
- Example display: `👤 GUEST-0012`

#### User Details Screen
- Guest ID is prominently displayed in user header section
- Shows as a blue badge below email (if any)
- Additional field in "More Information" section showing guest ID

#### Search Functionality
- Admins can now search for users by:
  - Display name
  - Email address
  - **Guest ID** (new)
  - User UID
- Example searches that work: `GUEST-0001`, `guest-12`, `Guest`

### 4. **Database Structure**

#### UserModel Changes
New field added to `UserModel`:
```dart
final String? guestId; // Unique ID for guest users (e.g., "GUEST-1234")
```

#### Firestore Document Structure
Guest user documents now include:
```json
{
  "uid": "firebase-generated-uid",
  "displayName": "GUEST-0001",
  "guestId": "GUEST-0001",
  "provider": 2,  // LoginProvider.anonymous
  "email": null,
  "photoURL": null,
  "totalScore": 0,
  "gamesPlayed": 0,
  "gamesWon": 0,
  "createdAt": "timestamp",
  "lastSeen": "timestamp",
  "isOnline": true
}
```

## Files Modified

### Core Models
- **`lib/models/user_model.dart`**
  - Added `guestId` field
  - Updated `fromFirebaseUser` factory to accept guest ID
  - Updated `fromFirestore` to load guest ID
  - Updated `toFirestore` to save guest ID
  - Updated `copyWith` method

### Services
- **`lib/services/auth_service.dart`**
  - Modified `signInAnonymously()` to generate guest ID
  - Updated display name to show guest ID
  
- **`lib/services/database_service.dart`**
  - Added `generateGuestId()` method for unique ID generation
  - Implements counting-based ID generation with fallback

### UI Components

#### Home Screen
- **`lib/widgets/home/welcome_section.dart`**
  - Updated to display guest ID for anonymous users
  - Watches `currentUserModelProvider` to get full user data including guest ID

#### Admin Panel
- **`lib/screens/admin/user_details_screen.dart`**
  - Added guest ID display in user header
  - Added guest ID field in user details section
  
- **`lib/widgets/admin/users_tab.dart`**
  - Updated search filter to include guest ID
  - Updated search hint text to mention guest ID
  - Modified `_filterUsers()` to search by guest ID
  
- **`lib/widgets/admin/user_info_card.dart`**
  - Added guest ID badge display for anonymous users

## Usage

### For Users
1. Click "Get Started" on login screen
2. Select "Guest Login" option
3. System automatically creates account with unique ID
4. User sees their guest ID on home screen: "بەخێرهاتنەوە، GUEST-0001!"

### For Admins
1. Navigate to admin panel → Users tab
2. Search for specific guest user by typing their guest ID (e.g., "GUEST-0001")
3. View user details to see complete guest information
4. Guest IDs are displayed in user cards and detail screens

## Benefits

1. **User Identification**: Each guest can now be uniquely identified
2. **User Support**: Admins can find specific guest users easily
3. **Analytics**: Better tracking of guest user behavior
4. **Communication**: Guest users can share their ID for support
5. **Accountability**: Actions can be traced to specific guest accounts

## Technical Notes

### ID Generation Algorithm
1. Count existing anonymous users in database
2. Increment count by 1
3. Format as `GUEST-XXXX` with zero-padding
4. Check for duplicates
5. If duplicate exists, use timestamp-based ID as fallback

### Performance Considerations
- ID generation uses Firestore count queries (efficient)
- Fallback to timestamp prevents conflicts
- Search includes guest ID without requiring additional indexes

## Future Enhancements

Potential improvements for the future:
1. Allow guests to convert to registered accounts while keeping guest ID
2. Add guest ID to game leaderboards
3. Show guest ID in game lobbies
4. Add guest ID to notifications
5. Implement guest ID based referral system

## Migration

Existing guest users (before this update) will:
- Not have a guest ID initially
- Receive a guest ID if they sign in again
- Continue to work normally with the app

To migrate existing guest users, run a manual script to:
1. Query all users with `provider = anonymous` and no `guestId`
2. Generate guest IDs for them
3. Update their documents and display names

## Testing

To test the system:
1. Sign out from the app
2. Click "Get Started" → "Guest Login"
3. Verify guest ID appears on home screen
4. Check admin panel shows the guest user with their ID
5. Test searching by guest ID in admin panel

---

**Last Updated**: October 11, 2025  
**Version**: 1.0  
**Author**: Development Team
