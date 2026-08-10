# Flutter wraps its own engine rules, but plugins that use reflection need
# keeping explicitly or they break only in minified release builds.

# Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# Play Core — referenced by Flutter's deferred components even when unused
-dontwarn com.google.android.play.core.**

# Keep annotations used for runtime lookups
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# Line numbers for readable release stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
