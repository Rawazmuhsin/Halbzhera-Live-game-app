# Firestore Setup for Broadcast Notifications

## Required Firestore Security Rules

Add these rules to your Firestore Security Rules in the Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read access to users collection for authenticated users
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow read access to categories, questions for authenticated users
    match /categories/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
    
    match /questions/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
    
    // Broadcast notifications - admin can write, all authenticated users can read
    match /broadcast_notifications/{notificationId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
    
    // Game-related collections
    match /live_games/{gameId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
    
    match /live_answers/{answerId} {
      allow read, write: if request.auth != null;
    }
    
    match /game_schedule/{scheduleId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
    
    match /leaderboard/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Legacy collections
    match /quizzes/{document} {
      allow read, write: if request.auth != null;
    }
    
    match /rooms/{document} {
      allow read, write: if request.auth != null;
    }
    
    match /scores/{document} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Required Firestore Indexes

If you want to enable ordering by timestamp in queries, create these composite indexes in the Firebase Console:

### Broadcast Notifications Index
- Collection: `broadcast_notifications`
- Fields:
  - `isActive` (Ascending)
  - `timestamp` (Descending)
  
**Index URL:** https://console.firebase.google.com/v1/r/project/halbzhera-quiz-app-62c6e/firestore/indexes

### How to create the index:
1. Go to Firebase Console
2. Select your project: `halbzhera-quiz-app-62c6e`
3. Go to Firestore Database
4. Click on "Indexes" tab
5. Click "Create Index"
6. Collection ID: `broadcast_notifications`
7. Add fields:
   - Field: `isActive`, Type: `Ascending`
   - Field: `timestamp`, Type: `Descending`
8. Click "Create"

## Current Implementation Status

✅ **Broadcast notification system is working** with simplified queries that don't require indexes.

✅ **Admin can send notifications** to all users through the send notification screen.

✅ **All users receive notifications** in real-time when they have the app open.

⚠️ **Index creation is optional** - the current implementation works without indexes but adding them will improve query performance.

## Testing the System

1. **Send a test notification:**
   - Open the app as admin
   - Go to notification sending screen
   - Send a test message
   - Check that it appears in Firestore under `broadcast_notifications`

2. **Receive notifications:**
   - Open the app on another device/user
   - Wait for real-time listener to detect new notifications
   - Check that local notification appears

3. **Troubleshooting:**
   - Check Flutter console for debug messages
   - Verify Firebase initialization is successful
   - Ensure notification permissions are granted
   - Check Firestore console for stored notifications

## Notification Flow

1. **Admin sends notification** → Stored in Firestore `broadcast_notifications` collection
2. **Real-time listeners** on all connected devices detect the new notification
3. **Local notification** is triggered on each device
4. **User sees notification** in their notification tray

This system works **without requiring server keys** and is **free on Firebase**.
