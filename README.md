# Family Medicine Tracker

A cross-platform mobile application developed with Flutter to assist families in managing daily medication schedules and inventory for multiple members. The app ensures medication adherence through a smart, grouped notification system, flexible scheduling options, and real-time stock tracking tailored for various family roles.

## Features

### User & Role Management

* **Dynamic Profiles:** Create and manage profiles for different family members (e.g., Grandpa, Grandma, Children).
* **Custom Avatars:** Assign distinct avatars to each profile for quick visual identification throughout the app.
* **Data Integrity:** Deleting a user profile automatically cleans up all associated medications and cancels pending notifications to prevent orphaned data.

### Advanced Scheduling & Calendar

* **Flexible Frequencies:** Medications can be scheduled for "Every Day" or specific days of the week (e.g., Mondays and Thursdays only).
* **Calendar View:** A dedicated calendar tab provides a weekly overview of all scheduled medications, grouped by time slots and family members.
* **Time Slots:** Medications are organized into four customizable periods: Morning, Noon, Evening, and Night.

### Daily Tracking & Interaction

* **Interactive List:** The "Today" view filters medications based on the current day of the week and active profiles.
* **Status Toggling:** Medications marked as "Taken" visually change to green with a strikethrough effect.
* **Undo Capability:** Users can reverse a "Taken" action. This restores the stock count and automatically re-schedules the reminder notification for that dose.

### Smart Notification System

* **Grouped Alerts:** Instead of receiving multiple notifications for different pills at the same time, the system bundles them into a single alert (e.g., "Grandpa, Morning meds: Aspirin, Vitamin C").
* **Intelligent Follow-ups:** If medications are missed, follow-up reminders trigger at 15 and 30-minute intervals.
* **Dynamic Content:** If a user takes only one of several medications scheduled for a specific time, the subsequent reminder automatically updates to list only the remaining untaken medicines.
* **Auto-Cancellation:** Completing all medications for a specific time slot automatically cancels all pending reminders for that slot.

### Inventory & Stock Management

* **Real-Time Sync:** Utilizes Firebase Firestore to synchronize stock levels across all family devices instantly.
* **Stock Warnings:** Visual indicators highlight medications when stock drops below user-defined critical levels (e.g., fewer than 10 units).
* **Search & Filter:** Easily search the medication inventory by name or filter by owner.

### Customization

* **Global Time Settings:** Users can define specific hours for "Morning," "Noon," "Evening," and "Night" via the Settings page. Changing these times automatically recalculates and reschedules all existing notifications.

## Technical Architecture & Logic

### Notification Workflow

The application uses a sophisticated ID generation and grouping logic to handle notifications without overwhelming the user:

1. **ID Generation:** Unique notification IDs are generated using a hash of the Person, Time Slot, and Day of the Week.
2. **Bundling:** When a medication is added or edited, the app queries all medications for that specific person and time slot, consolidating them into a single notification payload.
3. **Dynamic Updates:** When a user interacts with the app (marking a med as taken), the `NotificationService` recalculates the pending list. If items remain, the reminder content is updated; if the list is empty, the reminder group is cancelled.

### Tech Stack

* **Framework:** Flutter (Dart)
* **Backend & Database:** Firebase Firestore
* **Local Storage:** shared_preferences (for user time settings and local configurations)
* **Notifications:** flutter_local_notifications
* **Time Management:** timezone package
