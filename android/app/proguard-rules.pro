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

# Google Play Core — Flutter's embedding references SplitCompat/SplitInstall
# (deferred components / Play Store dynamic delivery) which this app does not use.
# Without these rules R8 fails minifyReleaseWithR8 with "Missing class
# com.google.android.play.core.*". Safe to ignore for a non-deferred build.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
