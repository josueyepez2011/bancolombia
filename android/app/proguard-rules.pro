# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Métodos nativos
-keepclasseswithmembers class * {
    native <methods>;
}

-dontwarn io.flutter.embedding.**
