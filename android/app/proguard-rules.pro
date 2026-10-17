# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# SQLite / Sqflite
-keep class org.sqlite.** { *; }
-keep class com.tekartik.sqflite.** { *; }

# Sentry
-keepattributes LineNumberTable,SourceFile
-dontwarn org.slf4j.**
