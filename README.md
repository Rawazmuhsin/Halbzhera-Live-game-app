# 🎯 Halbzhera - Live Quiz Game App

A comprehensive Flutter-based quiz application with Kurdish interface, featuring a complete admin panel for game management and real-time player interactions.

## 🌟 Features

### 📱 **Core App Features**
- **Kurdish Interface**: Fully localized in Kurdish language
- **Live Quiz Games**: Real-time multiplayer quiz sessions
- **User Authentication**: Firebase Auth with Google Sign-in
- **Responsive Design**: Works seamlessly on mobile and tablet devices

### 🛠️ **Admin Panel**
- **Games Management**: Create, edit, and manage scheduled games
- **User Management**: View and manage user accounts  
- **Analytics Dashboard**: Performance metrics and insights
- **Real-time Monitoring**: Live updates and notifications

### 🎮 **Game Creation System**
- **Flexible Categories**: Text-based category input for any subject
- **Comprehensive Forms**: Name, description, prize, duration, participant limits
- **Smart Scheduling**: Date/time picker for future games
- **Validation**: Kurdish error messages and form validation
- **Tags & Metadata**: Custom tags and game settings

## 🏗️ **Technical Architecture**

### **Frontend**
- **Flutter**: Cross-platform mobile development
- **Riverpod**: State management for reactive UI
- **Material Design**: With Kurdish localization
- **Responsive Layout**: Adaptive design for different screen sizes

### **Backend**
- **Firebase Firestore**: NoSQL database with real-time updates
- **Firebase Auth**: Authentication and user management
- **Cloud Functions**: Server-side logic (if applicable)
- **Composite Indexes**: Optimized database queries

### **Project Structure**
```
lib/
├── models/              # Data models (ScheduledGameModel, etc.)
├── providers/           # Riverpod state management
├── screens/            
│   ├── admin/          # Admin panel screens
│   └── auth/           # Authentication screens
├── services/           # Database and auth services  
├── widgets/
│   ├── admin/          # Admin-specific UI components
│   └── common/         # Shared UI components
├── utils/              # Constants and utilities
└── config/             # App configuration
```

## 🚀 **Getting Started**

### **Prerequisites**
- Flutter SDK (3.0+)
- Firebase project setup
- Android Studio / VS Code
- Git

### **Installation**

1. **Clone the repository**
   ```bash
   git clone https://github.com/Rawazmuhsin/Halbzhera-Live-game-app.git
   cd Halbzhera-Live-game-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Deploy Firestore indexes:
     ```bash
     firebase deploy --only firestore:indexes
     ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📊 **Database Schema**

### **Collections**
- `scheduled_games`: Future quiz games with scheduling info
- `live_games`: Currently active quiz sessions
- `users`: User profiles and authentication data
- `categories`: Game categories and subjects

### **Key Indexes**
```json
{
  "scheduled_games": [
    "status + scheduledTime",
    "scheduledTime + status"
  ],
  "live_games": [
    "status + scheduledTime",
    "status + finishedAt"
  ]
}
```

## 🎯 **Usage**

### **For Administrators**
1. **Login**: Use admin credentials to access admin panel
2. **Create Games**: Navigate to Games tab → "یاری نوێ" button
3. **Manage Users**: View user statistics and manage accounts
4. **Monitor Analytics**: Track game performance and user engagement

### **For Players**
1. **Sign Up/Login**: Create account or login with Google
2. **Join Games**: Browse and join available quiz games
3. **Play Live**: Participate in real-time quiz sessions
4. **Track Progress**: View scores and achievements

## 🔧 **Recent Updates**

### **✨ Latest Features (August 2025)**
- Complete admin panel with comprehensive game management
- Text-based category selection for improved UX
- Fixed Firestore index issues for better performance
- Working logout functionality with Kurdish interface
- Responsive design improvements for admin pages

## 🤝 **Contributing**

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 **Contact**

**Rawaz Muhsin** - [@Rawazmuhsin](https://github.com/Rawazmuhsin)

**Project Link**: [https://github.com/Rawazmuhsin/Halbzhera-Live-game-app](https://github.com/Rawazmuhsin/Halbzhera-Live-game-app)

---

## 🙏 **Acknowledgments**

- Flutter team for the amazing framework
- Firebase for backend services
- Kurdish language community for localization support
- Contributors and testers

---

*Built with ❤️ for the Kurdish community*
