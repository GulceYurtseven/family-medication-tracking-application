# Flutter Local Notifications Kütüphanesi için Kurallar
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.core.app.** { *; }
-keep class android.support.v4.app.** { *; }

# GSON
-keep class com.google.gson.** { *; }

# Standart Flutter korumaları
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# --- YENİ EKLENENLER (HATA DÜZELTME) ---
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**