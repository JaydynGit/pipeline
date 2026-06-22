# Google ML Kit Proguard Rules to prevent R8 from stripping necessary classes during release builds
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google_mlkit_commons.** { *; }
-dontwarn com.google_mlkit_commons.**
-keep class com.google_mlkit_text_recognition.** { *; }
-dontwarn com.google_mlkit_text_recognition.**
-keep class com.google_mlkit_subject_segmentation.** { *; }
-dontwarn com.google_mlkit_subject_segmentation.**
