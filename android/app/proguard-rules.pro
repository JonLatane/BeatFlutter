-dontobfuscate
-keep class androidx.lifecycle.DefaultLifecycleObserver
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
# Skip runtime check for isOnAndroidDevice().
# One line to make it easy to remove with sed.
-assumevalues class com.google.protobuf.Android { static boolean ASSUME_ANDROID return true; }

-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite {
  <fields>;
}
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }
