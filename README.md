# Family Medicine Tracker (Aile İlaç Takip)

A cross-platform (iOS & Android) mobile application developed with Flutter to assist families in managing daily medication schedules, inventory, and adherence for multiple members.

The app utilizes a **Family Code System** to synchronize data across devices instantly using Firebase, ensuring caregivers and family members are always on the same page.

### Family Ecosystem & Synchronization
* **Family Code System:** No complex email sign-ups. Users join a family ecosystem simply by entering a unique "Family Code."
* **Real-Time Sync:** Utilizes **Firebase Firestore** to synchronize profiles, medicines, stock levels, and logs across all devices instantly.

### User & Role Management
* **Dynamic Profiles:** Create and manage profiles for different family members (e.g., Grandpa, Grandma, Children).
* **Custom Avatars:** Assign distinct avatars to each profile for quick visual identification.
* **Data Integrity:** Deleting a user profile safely cleans up associated medications and logs.

### Advanced Scheduling & Calendar
* **Flexible Frequencies:** Schedule medications for "Every Day" or specific days (e.g., Mon, Wed, Fri).
* **Time Slots:** Organized into four customizable periods: **Morning, Noon, Evening, and Night**.
* **Calendar View:** A weekly overview of all scheduled medications grouped by time slots and family members.

### Smart Notification System (Platform Adaptive)
* **Grouped Alerts:** Bundles multiple medications for the same time slot into a single notification (e.g., "Grandpa: Morning meds (Aspirin, Vitamin C)").
* **Actionable Reminders:** Notifications remind users specifically of what hasn't been taken yet.
* **Auto-Cancellation:** Marking meds as taken automatically cancels pending reminders for that specific slot.

### Inventory & Stock Management
* **Stock Tracking:** Automatically deducts stock when a medication is marked as "Taken."
* **Low Stock Warnings:** Visual indicators highlight medications when stock drops below user-defined critical levels.
* **Undo Capability:** Reversing a "Taken" action restores the stock count and re-activates the schedule.

## Technical Architecture & Logic

This application implements **Platform Specific Logic** to handle the differences between Android and iOS execution limitations.

### Platform Specific Implementation

#### Android
* **Background Execution:** Uses `android_alarm_manager_plus` for precise scheduling.
* **Intelligent Follow-ups:** If medications are missed, the app wakes up in the background to trigger follow-up alarms at 15, 30, and 45-minute intervals.
* **Exact Alarms:** Requests `SCHEDULE_EXACT_ALARM` permissions for precise timing.

#### iOS (iPhone)
* **Standard Notifications:** Uses the native iOS notification system via `flutter_local_notifications`.
* **Battery Optimization:** Adheres to Apple's background execution policies by bypassing `AndroidAlarmManager` calls to prevent crashes (`MissingPluginException`) and battery drain.
* **Permissions:** Handles iOS-specific permission requests for Alerts, Badges, and Sounds.

### Tech Stack

* **Framework:** Flutter (Dart)
* **Backend:** Firebase Firestore (NoSQL Database)
* **Init & Core:** `firebase_core`
* **Local Storage:** `shared_preferences` (For storing Family Code and local settings)
* **Notifications:** `flutter_local_notifications`
* **Android Background:** `android_alarm_manager_plus` (Android only)
* **Time Management:** `timezone` package

## Installation & Setup

1.  **Clone the repository**
    ```bash
    git clone [https://github.com/yourusername/family-medication-tracking.git](https://github.com/yourusername/family-medication-tracking.git)
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup**
    * **Android:** Place `google-services.json` in `android/app/`.
    * **iOS:** Place `GoogleService-Info.plist` in `ios/Runner/` via Xcode (Ensure "Target Membership" is checked for Runner).

4.  **iOS Specifics (CocoaPods)**
    ```bash
    cd ios
    rm -rf Pods
    rm Podfile.lock
    pod install --repo-update
    cd ..
    ```

5.  **Run the App**
    * **Android:** `flutter run`
    * **iOS:** `flutter run --release` (Physical device recommended for notifications)