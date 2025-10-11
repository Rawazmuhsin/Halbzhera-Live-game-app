# Quick Reference: Guest User System

## What Changed?

Guest users now get unique IDs like **GUEST-0001**, **GUEST-0002**, etc.

## Where to See Guest IDs

### 1. Home Screen
- **Before**: "بەخێرهاتنەوە، میوان!"
- **After**: "بەخێرهاتنەوە، GUEST-0001!"

### 2. Admin Panel - User List
Look for the blue badge with 👤 icon showing the guest ID

### 3. Admin Panel - User Details
- Shows in user header (blue badge)
- Shows in "More Information" section

### 4. Admin Panel - Search
Search by typing:
- `GUEST-0001` (exact match)
- `guest` (partial match)
- `0001` (number only)

## How It Works

### New Guest Sign-In
1. User clicks "Get Started"
2. Chooses "Guest Login"
3. System generates unique ID: GUEST-XXXX
4. User's display name becomes their guest ID
5. Guest ID stored in database

### ID Generation
```
Count existing guests → Add 1 → Format as GUEST-XXXX
Example: 42 guests exist → New guest gets GUEST-0043
```

## Code Changes Summary

### 1. UserModel (`lib/models/user_model.dart`)
```dart
// New field
final String? guestId;
```

### 2. Auth Service (`lib/services/auth_service.dart`)
```dart
// Generates guest ID during anonymous sign-in
final guestId = await _databaseService.generateGuestId();
```

### 3. Database Service (`lib/services/database_service.dart`)
```dart
// New method
Future<String> generateGuestId() async { ... }
```

### 4. Welcome Section (`lib/widgets/home/welcome_section.dart`)
```dart
// Now displays guest ID for anonymous users
if (userData?.guestId != null) {
  displayName = userData!.guestId!;
}
```

### 5. Admin Screens
- User details shows guest ID
- User cards show guest ID badge
- Search includes guest ID matching

## Testing Checklist

- [ ] Sign in as guest
- [ ] Check home screen shows guest ID
- [ ] Open admin panel
- [ ] Find guest user in list
- [ ] Click to view user details
- [ ] Verify guest ID is displayed
- [ ] Test search by guest ID
- [ ] Test search by partial guest ID

## Database Structure

### Firestore Document (Guest User)
```json
{
  "uid": "xyz123...",
  "displayName": "GUEST-0001",
  "guestId": "GUEST-0001",
  "provider": 2,
  "email": null,
  "totalScore": 0,
  "gamesPlayed": 0,
  "isOnline": true,
  "createdAt": "timestamp",
  "lastSeen": "timestamp"
}
```

## Useful Firestore Queries

### Find all guest users:
```javascript
db.collection('users')
  .where('provider', '==', 2)  // anonymous
  .get()
```

### Find specific guest:
```javascript
db.collection('users')
  .where('guestId', '==', 'GUEST-0001')
  .get()
```

### Count guest users:
```javascript
db.collection('users')
  .where('provider', '==', 2)
  .count()
  .get()
```

## Migration Notes

### For Existing Guest Users
If you have existing guest users without IDs:

1. They will continue to work normally
2. Next time they sign in, they'll get a guest ID
3. Or run this Firestore script to assign IDs to all:

```javascript
// In Firebase Console
const users = await db.collection('users')
  .where('provider', '==', 2)
  .where('guestId', '==', null)
  .get();

let count = await db.collection('users')
  .where('provider', '==', 2)
  .count()
  .get();

users.forEach((doc, index) => {
  const guestId = `GUEST-${String(count.data().count + index + 1).padStart(4, '0')}`;
  doc.ref.update({
    guestId: guestId,
    displayName: guestId
  });
});
```

## Troubleshooting

### Guest ID not showing on home screen?
1. Check if user is signed in as guest
2. Verify `guestId` field exists in Firestore
3. Check console for errors
4. Try signing out and in again

### Can't find guest user in admin search?
1. Verify guest ID exists in database
2. Check search query matches format (e.g., "GUEST-0001")
3. Try partial search (e.g., "guest" or "0001")

### Duplicate guest IDs?
- System includes duplicate check
- Falls back to timestamp-based ID
- Very unlikely with current implementation

## Support

For issues or questions:
1. Check Firestore console for user data
2. Look at Flutter console logs
3. Review `GUEST_USER_SYSTEM.md` for detailed info
4. Check Firebase Auth for anonymous user

---

**Quick Commands**

Run tests:
```bash
flutter test test/guest_user_test.dart
```

Check for errors:
```bash
flutter analyze
```

Build app:
```bash
flutter run
```
