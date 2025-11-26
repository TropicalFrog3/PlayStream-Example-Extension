# Add project specific ProGuard rules here.

# Keep QuickJS native libraries and classes
-keep class com.whl.quickjs.** { *; }
-keepclassmembers class com.whl.quickjs.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve QuickJS wrapper classes
-keep class * implements com.whl.quickjs.wrapper.JSMethod { *; }

# Don't warn about QuickJS
-dontwarn com.whl.quickjs.**

# Keep OkHttp (already handled by OkHttp's own rules, but adding for completeness)
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep JavaScript interface annotations
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
