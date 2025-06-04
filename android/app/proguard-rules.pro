# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Play In-App Update and Play In-App Review
-keep class com.google.android.play.** { *; }
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-keep class com.google.android.play.core.review.** { *; }

# Important classes for Android 14 compatibility
-keep class com.google.android.play.core.common.PlayCoreDialogWrapperActivity
-keep class com.google.android.play.core.common.IntentSenderForResultStarter
-keep class com.google.android.play.core.listener.StateUpdatedListener

# Keep all native methods
-keepclasseswithmembers class * {
    native <methods>;
}

# Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Serializable
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Androidx
-keep class androidx.lifecycle.** { *; }
-keep class androidx.core.app.** { *; }

# Keep Kotlin Metadata
-keepattributes *Annotation*, InnerClasses
-keepattributes SourceFile, LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Remove debug logs in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
}

# Add rules to fix debug symbol stripping
-keepattributes LineNumberTable,SourceFile
-renamesourcefileattribute SourceFile
-keep public class * extends java.lang.Exception

# Don't strip native libraries
-keepattributes JNINamespace
-keep class * implements java.lang.annotation.Annotation { *; }
-keepclasseswithmembers,allowshrinking class * {
    native <methods>;
}
-keepclasseswithmembernames class * {
    native <methods>;
}
-dontwarn com.sun.jna.**
-dontwarn java.lang.instrument.**

# Prevent native library stripping
-keep class **.libflutter.so
-keep class **.libapp.so 