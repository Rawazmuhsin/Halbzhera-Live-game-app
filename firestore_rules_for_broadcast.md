# Firestore Security Rules for Broadcast Notifications

Add these rules to your Firestore security rules in the Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Existing rules for your other collections
    // ... your existing rules ...
    
    // Broadcast notifications rules
    match /broadcast_notifications/{notificationId} {
      // Allow admin to create and update notifications
      allow create, update: if request.auth != null && 
                               request.auth.token.email == 'rawazm318@gmail.com';
      
      // Allow all authenticated users to read notifications
      allow read: if request.auth != null;
      
      // Prevent deletion by anyone (for audit trail)
      allow delete: if false;
    }
  }
}
```

## Instructions:

1. Go to Firebase Console (https://console.firebase.google.com)
2. Select your project
3. Go to Firestore Database
4. Click on "Rules" tab
5. Add the broadcast_notifications rules above to your existing rules
6. Click "Publish" to save the rules

## Security Features:

- ✅ Only your admin email can create/send notifications
- ✅ All authenticated users can read notifications
- ✅ Notifications cannot be deleted (audit trail)
- ✅ Prevents unauthorized access
