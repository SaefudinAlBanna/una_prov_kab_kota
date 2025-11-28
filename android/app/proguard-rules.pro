# ==========================================================
# File: proguard-rules.pro (Versi FINAL & LEBIH KUAT)
# ==========================================================

# Flutter wrapper rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.**  { *; }

# [PERBAIKAN UTAMA] Aturan Google Play Core yang lebih kuat
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Firebase Core
-keep class com.google.firebase.** { *; }

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.android.gms.internal.firebase-auth.** { *; }

# Cloud Firestore
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# Supabase
-keep class io.supabase.** { *; }
-keep interface io.supabase.** { *; }
-dontwarn io.supabase.**
-keep class io.github.janivollmer.supabase.** { *; }
-keep interface io.github.janivollmer.supabase.** { *; }
-dontwarn io.github.janivollmer.supabase.**

# Aturan umum untuk model data
-keepattributes Signature
-keepattributes *Annotation*
-keepclassmembers,allowshrinking,allowobfuscation class * {
    @com.google.firebase.database.PropertyName <methods>;
    @com.google.firebase.firestore.PropertyName <methods>;
    @androidx.annotation.Keep <fields>;
    @androidx.annotation.Keep <methods>;
}