# Add project specific ProGuard rules here.

# For Firebase
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# For Firebase Auth
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

# For Google Sign In
-keep class com.google.android.gms.common.api.GoogleApi { *; }

# For Retrofit/Gson
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements okhttp3.Interceptor

# Keep Gson serializer/safe serializer class names
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }

# For Flutter
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.plugin.**
-dontwarn io.flutter.app.**
-dontwarn io.flutter.view.**
-dontwarn io.flutter.BuildConfig
-dontwarn io.flutter.util.**
-keep class io.flutter.** { *; }
-dontwarn androidx.lifecycle.Lifecycle

# For okio (dependency of Retrofit)
-dontwarn com.squareup.okio.**
-keep class com.squareup.okio.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep View related classes
-keep class android.support.v7.widget.** { *; }
-keep class android.widget.** { *; }

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}
