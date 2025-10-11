# Guest User System - Visual Flow

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER FLOW                                │
└─────────────────────────────────────────────────────────────────┘

1. Login Screen
   │
   ├─> "Get Started" button
   │
   └─> Login Bottom Sheet
       │
       ├─> [Google Login] ──> Regular User (has email/name)
       ├─> [Facebook Login] ─> Regular User (has email/name)
       └─> [Guest Login] ────> 🎯 Anonymous User
                               │
                               ├─> Auth Service
                               │   • signInAnonymously()
                               │   • Calls Firebase Auth
                               │
                               ├─> Database Service
                               │   • generateGuestId()
                               │   • Counts existing guests
                               │   • Generates GUEST-XXXX
                               │
                               └─> Creates User Document
                                   {
                                     uid: "xyz...",
                                     guestId: "GUEST-0001",
                                     displayName: "GUEST-0001",
                                     provider: anonymous
                                   }


┌─────────────────────────────────────────────────────────────────┐
│                      DISPLAY LOCATIONS                           │
└─────────────────────────────────────────────────────────────────┘

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ HOME SCREEN                                                     ┃
┃ ┌──────────────────────────────────────────────────────────┐  ┃
┃ │  🎮 Halbzhera                                             │  ┃
┃ │                                                           │  ┃
┃ │  ┌─────────────────────────────────────────────────┐     │  ┃
┃ │  │ بەخێرهاتنەوە، GUEST-0001! 👋                   │     │  ┃
┃ │  │ یاریە داهاتووەکان                              │     │  ┃
┃ │  └─────────────────────────────────────────────────┘     │  ┃
┃ │                                                           │  ┃
┃ │  [Upcoming Games...]                                      │  ┃
┃ └──────────────────────────────────────────────────────────┘  ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛


┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ ADMIN PANEL - User List                                        ┃
┃ ┌──────────────────────────────────────────────────────────┐  ┃
┃ │ 🔍 [Search by name, email, or guest ID...] [Filter ▼]   │  ┃
┃ │                                                           │  ┃
┃ │ ┌────────────────────────────────────────────────────┐   │  ┃
┃ │ │ 👤 GUEST-0001              📊 Stats   👁️ 🗑️         │   │  ┃
┃ │ │ 👤 GUEST-0001                                      │   │  ┃
┃ │ │ خاڵ: 150  یاری: 5  بردنەوە: 2  ڕێژە: 40.0%      │   │  ┃
┃ │ │ 🟢 چالاک                                           │   │  ┃
┃ │ └────────────────────────────────────────────────────┘   │  ┃
┃ │                                                           │  ┃
┃ │ ┌────────────────────────────────────────────────────┐   │  ┃
┃ │ │ 👤 John Doe                📊 Stats   👁️ 🗑️        │   │  ┃
┃ │ │ john@example.com                                   │   │  ┃
┃ │ │ خاڵ: 250  یاری: 10  بردنەوە: 6  ڕێژە: 60.0%     │   │  ┃
┃ │ │ 🔴 ناچالاک                                         │   │  ┃
┃ │ └────────────────────────────────────────────────────┘   │  ┃
┃ └──────────────────────────────────────────────────────────┘  ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛


┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ ADMIN PANEL - User Details                                     ┃
┃ ┌──────────────────────────────────────────────────────────┐  ┃
┃ │ ← زانیاریەکانی بەکارهێنەر                               │  ┃
┃ │                                                           │  ┃
┃ │ ┌────────────────────────────────────────────────────┐   │  ┃
┃ │ │  👤  GUEST-0001                                    │   │  ┃
┃ │ │      👤 GUEST-0001  (Guest ID Badge)               │   │  ┃
┃ │ │      🟢 چالاک                                      │   │  ┃
┃ │ └────────────────────────────────────────────────────┘   │  ┃
┃ │                                                           │  ┃
┃ │ ┌─ ئامارەکان ────────────────────────────────────────┐   │  ┃
┃ │ │  ⭐ کۆی خاڵ: 150    🎮 یاریکراو: 5                │   │  ┃
┃ │ │  🏆 بردنەوە: 2      📈 ڕێژە: 40.0%               │   │  ┃
┃ │ └────────────────────────────────────────────────────┘   │  ┃
┃ │                                                           │  ┃
┃ │ ┌─ زانیاریەکانی زیاتر ─────────────────────────────┐   │  ┃
┃ │ │  ناسنامەی بەکارهێنەر: xyz123abc...                │   │  ┃
┃ │ │  ناسنامەی میوان: GUEST-0001 ⭐                   │   │  ┃
┃ │ │  دواجار بینراوە: 5 خولەک لەمەوبەر                 │   │  ┃
┃ │ │  جۆری چوونەژوورەوە: نەناسراو                       │   │  ┃
┃ │ └────────────────────────────────────────────────────┘   │  ┃
┃ └──────────────────────────────────────────────────────────┘  ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛


┌─────────────────────────────────────────────────────────────────┐
│                      DATA STRUCTURE                              │
└─────────────────────────────────────────────────────────────────┘

Firestore: users/{userId}
┌────────────────────────────────────────────────┐
│ Regular User Document                          │
├────────────────────────────────────────────────┤
│ uid: "abc123..."                               │
│ email: "user@example.com"                      │
│ displayName: "John Doe"                        │
│ photoURL: "https://..."                        │
│ provider: 0  (google)                          │
│ guestId: null                                  │
│ totalScore: 250                                │
│ gamesPlayed: 10                                │
│ ...                                            │
└────────────────────────────────────────────────┘

Firestore: users/{userId}
┌────────────────────────────────────────────────┐
│ Guest User Document                            │
├────────────────────────────────────────────────┤
│ uid: "xyz789..."                               │
│ email: null                                    │
│ displayName: "GUEST-0001" ⭐                   │
│ photoURL: null                                 │
│ provider: 2  (anonymous)                       │
│ guestId: "GUEST-0001" ⭐ NEW!                  │
│ totalScore: 150                                │
│ gamesPlayed: 5                                 │
│ ...                                            │
└────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                   SEARCH FUNCTIONALITY                           │
└─────────────────────────────────────────────────────────────────┘

Search Query Flow:
┌──────────────────┐
│ User types in    │
│ search box:      │
│ "GUEST-0001"     │
└────────┬─────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│ Filter Function                                 │
│ • Check displayName                             │
│ • Check email                                   │
│ • Check guestId ⭐ NEW!                         │
│ • Check uid                                     │
└────────┬────────────────────────────────────────┘
         │
         ▼
┌──────────────────┐
│ Match Found!     │
│ Display user in  │
│ results          │
└──────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                   ID GENERATION LOGIC                            │
└─────────────────────────────────────────────────────────────────┘

Step 1: Count existing guests
   ↓
   Query: users.where('provider', '==', 2).count()
   Result: 42 guests exist

Step 2: Generate new ID
   ↓
   nextNumber = 42 + 1 = 43
   guestId = "GUEST-" + padLeft(43, 4, '0')
   guestId = "GUEST-0043"

Step 3: Check for duplicates
   ↓
   Query: users.where('guestId', '==', 'GUEST-0043')
   
   If exists:
      ↓
      Fallback to timestamp:
      timestamp = 1697012345678
      guestId = "GUEST-345678"
   
   If not exists:
      ↓
      Use generated: "GUEST-0043" ✓

Step 4: Save to database
   ↓
   Create user document with guestId field
   Update displayName to match guestId


┌─────────────────────────────────────────────────────────────────┐
│                    COMPONENT FLOW                                │
└─────────────────────────────────────────────────────────────────┘

           LoginScreen
                │
                ├─> LoginBottomSheet
                │        │
                │        └─> onGuestLogin()
                │                 │
                │                 ▼
                │           AuthNotifier
                │                 │
                │                 └─> signInAnonymously()
                │                          │
                │                          ▼
                │                   AuthService
                │                          │
                │                          ├─> Firebase Auth
                │                          │   • signInAnonymously()
                │                          │
                │                          ├─> DatabaseService
                │                          │   • generateGuestId()
                │                          │   • createOrUpdateUser()
                │                          │
                │                          └─> Returns UserModel
                │                                    │
                ▼                                    ▼
           AuthGate ───────────────────────> HomeScreen
                                                    │
                                                    └─> WelcomeSection
                                                         │
                                                         └─> Shows: "GUEST-0001"


┌─────────────────────────────────────────────────────────────────┐
│                      KEY BENEFITS                                │
└─────────────────────────────────────────────────────────────────┘

✅ Unique Identification
   Each guest has a memorable ID (GUEST-0001)
   
✅ Easy Search
   Admins can quickly find specific guests
   
✅ Better Support
   Users can share their ID for help
   
✅ User Recognition
   Guests see their ID on home screen
   
✅ Analytics
   Track individual guest behavior
   
✅ No Email Required
   Full functionality without signup


┌─────────────────────────────────────────────────────────────────┐
│                      CODE LOCATIONS                              │
└─────────────────────────────────────────────────────────────────┘

🎯 Core Logic:
   ├─ UserModel: lib/models/user_model.dart
   ├─ Auth Service: lib/services/auth_service.dart
   └─ Database Service: lib/services/database_service.dart

🎨 UI Components:
   ├─ Home Welcome: lib/widgets/home/welcome_section.dart
   ├─ User Details: lib/screens/admin/user_details_screen.dart
   ├─ Users Tab: lib/widgets/admin/users_tab.dart
   └─ User Card: lib/widgets/admin/user_info_card.dart

📚 Documentation:
   ├─ Full Guide: GUEST_USER_SYSTEM.md
   ├─ Quick Ref: GUEST_USER_QUICK_GUIDE.md
   └─ This File: GUEST_USER_VISUAL_FLOW.md

🧪 Tests:
   └─ Unit Tests: test/guest_user_test.dart
