# Add Questions Feature Documentation

## Overview
The Add Questions feature allows administrators to add questions to game sections they have created. This ensures that each game section has enough questions (10-15) to run properly.

## ✅ **FIXED: Real-time Question Counting**

### **The Problem:**
- Question progress was always showing `0/10` 
- No real-time updates when questions were added
- Progress didn't reflect actual database content

### **The Solution:**
- **24-Hour Window Counting**: Questions are counted only from the last 24 hours
- **Real-time Updates**: Progress updates immediately when questions are added
- **Database Filtered Query**: Uses `createdAt > (now - 24 hours)` filter

### **How the Counting Works:**
```dart
// Counts ONLY questions added in last 24 hours
final realTimeQuestionCountProvider = 
    FutureProvider.family<int, String>((ref, categoryName) async {
  final yesterday = DateTime.now().subtract(const Duration(hours: 24));
  
  final snapshot = await FirebaseConfig.questions
      .where('category', isEqualTo: categoryName)
      .where('isActive', isEqualTo: true)
      .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
      .get();
  
  return snapshot.docs.length; // Only last 24 hours!
});
```

## How to Use

### 1. Access the Feature
1. Log in as an admin
2. Go to the Admin Dashboard
3. Click on the "Games" tab
4. Click the "پرسیار زیادکردن" (Add Questions) button

### 2. Select a Game Section
- The system will show all created game sections
- Each section displays:
  - **Real Question Count**: Shows actual count like `5/10`, `12/10`, etc.
  - **Status Badge**: 
    - 🔴 **ناتەواو** (Incomplete) - Less than 10 questions
    - 🟡 **کەم** (Low) - 10-14 questions
    - 🟢 **تەواو** (Complete) - 15+ questions
  - **Progress Bar**: Visual indicator of completion

### 3. Add Questions to a Section
1. Click "پرسیار زیادکردن" (Add Questions) on any game section card
2. Fill out the question form:
   - **Question text**: Write your question
   - **Question type**: Choose from:
     - Multiple Choice (4 options)
     - True/False (2 options)
     - Fill in the Blank
   - **Difficulty**: Easy, Medium, or Hard
   - **Options**: Fill in the answer choices (if applicable)
   - **Correct Answer**: Select or type the correct answer
   - **Points**: Set point value (default 10)
   - **Time Limit**: Set time limit in seconds (default 15)
   - **Explanation**: Optional explanation for the answer

3. Click "پرسیار دروستبکە" (Create Question) to save
4. **Progress Updates Automatically**: See count go from `5/10` → `6/10` → `7/10` etc.

### 4. Question Requirements
- **Minimum**: 10 questions per section to start a game
- **Recommended**: 15 questions per section for complete functionality
- Questions are stored in the Firebase `questions` collection
- Each question is linked to its game section category

## Real-time Progress Examples

| Questions Added | Display | Status | Badge Color |
|----------------|---------|--------|-------------|
| 0 questions | `0/10` | ناتەواو (Incomplete) | 🔴 Red |
| 5 questions | `5/10` | ناتەواو (Incomplete) | 🔴 Red |
| 10 questions | `10/10` | کەم (Low) | 🟡 Yellow |
| 15 questions | `15/10` | تەواو (Complete) | 🟢 Green |
| 20 questions | `20/10` | تەواو (Complete) | 🟢 Green |

## Question Types

### Multiple Choice
- Provides 4 options for players to choose from
- Good for testing specific knowledge
- Most commonly used question type

### True/False
- Simple yes/no or true/false questions
- Quick to answer
- Good for facts and statements

### Fill in the Blank
- Players type their answer
- Requires exact text matching
- Good for names, dates, and specific terms

## Technical Implementation

### **Question Counting System:**
- **Provider**: `realTimeQuestionCountProvider` counts only last 24 hours
- **Database Query**: Filters by `createdAt > (now - 24 hours)`
- **Filtering**: Only counts active questions for the specific category added recently
- **Real-time**: Automatically refreshes when questions are added

### **Database Structure:**
```firestore
questions/
  ├── questionId1/
  │   ├── category: "مێژوو"          // Matches game section
  │   ├── question: "..."
  │   ├── isActive: true
  │   ├── createdAt: timestamp
  │   └── ...
  └── questionId2/
      ├── category: "زانست"
      └── ...
```

### **Progress Update Flow:**
1. User creates question → Stored in Firestore with `createdAt` timestamp
2. `realTimeQuestionCountProvider` → Queries only last 24 hours
3. UI automatically updates → Shows count of recent questions
4. Progress bars and badges update → Real-time feedback for recent activity

## Features
- ✅ **Real-time counting** from actual database documents
- ✅ **Form validation** ensures all required fields are filled
- ✅ **Progress tracking** with visual indicators
- ✅ **Kurdish language** interface
- ✅ **Responsive design** for different screen sizes
- ✅ **Error handling** and user feedback
- ✅ **Auto-refresh** after adding questions

## Future Enhancements
- Bulk question import from CSV/Excel
- Question templates and categories
- Question difficulty analysis
- Image support for questions
- Question bank sharing between categories
