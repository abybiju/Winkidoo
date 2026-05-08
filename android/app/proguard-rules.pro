# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / GoTrue
-keep class io.supabase.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# Suppress warnings for common libraries
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
