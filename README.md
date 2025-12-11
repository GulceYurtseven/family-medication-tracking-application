# Family Medicine Tracker

A cross-platform mobile application developed with Flutter to assist elderly family members in managing their daily medication schedules and inventory. The app ensures medication adherence through a smart notification system and real-time stock tracking tailored for multiple family members.

## Features
### Daily Tracking & Schedule

Role-Based Views: distinct sections for different family members (e.g., Grandpa & Grandma) for easy readability.

Visual Cues: Intuitive icons for medication times (🌅 Morning, ☀️ Noon, 🌙 Evening, 🛌 Night).

Dynamic Status: Medication cards change appearance when marked as "Taken" (Green/Strikethrough).

## Smart Notification System
Scheduled Alerts: Sends local notifications at specific times (customizable via Settings).

Intelligent Reminders: If a medication is not marked as "Taken," the system triggers follow-up reminders at 15, 30, and 45-minute intervals.

Auto-Cancellation: Marking a medication as taken automatically cancels pending reminder notifications for that specific dose.

## Inventory & Stock Management
Real-Time Sync: Uses Firebase Firestore to sync stock levels across all family devices instantly.

Low Stock Alerts: Visual warning (Red Highlights) when medication stock drops below critical levels (5 units).

Search Functionality: Filter medication list by name for quick stock checks.

## Customization
Flexible Scheduling: Users can define and update specific times for "Morning," "Noon," "Evening," and "Night" doses via the Settings page.

CRUD Operations: Add, Edit, and Delete medications with support for multiple daily doses.

## Key Logic Explanation
Notification Workflow: The app generates a unique base ID for each medication. When a medication is scheduled for multiple times (e.g., Morning and Evening):

Main Alarm: Triggers at the user-defined time.

Follow-up Alarms: Scheduled for +15, +30, and +45 minutes relative to the main alarm.

Cancellation: When the user taps the "Taken" button, the app calculates the specific IDs for the follow-up alarms and cancels them using flutter_local_notifications, preventing unnecessary disturbance.

## Tech Stack
Framework: Flutter (Dart)

Backend & Database: Firebase Firestore

Local Storage: shared_preferences (for storing user preferences/time settings)

Notifications: flutter_local_notifications

Time Management: timezone package
