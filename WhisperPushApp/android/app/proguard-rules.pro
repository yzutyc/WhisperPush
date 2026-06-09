# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter Play Core (SplitCompat)
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter deferred components
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# 华为 HMS 核心
-keep class com.huawei.hms.** { *; }
-keep class com.huawei.hianalytics.** { *; }
-keep class com.huawei.hms.framework.** { *; }
-keep class com.huawei.hms.support.** { *; }
-keep class com.huawei.hms.availableupdate.** { *; }

# 华为安全组件
-keep class com.huawei.secure.android.** { *; }

# Huawei OS 扩展
-keep class com.huawei.android.os.** { *; }
-keep class com.huawei.libcore.io.** { *; }

# Bouncy Castle (used by Huawei)
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Huawei Push 插件
-keep class com.huawei.hms.flutter.push.** { *; }

# 不警告缺失的华为类
-dontwarn com.huawei.hms.**
-dontwarn com.huawei.hianalytics.**
-dontwarn com.huawei.android.**
-dontwarn com.huawei.libcore.**

# Keep annotations
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes SourceFile
-keepattributes LineNumberTable

# Keep Huawei Analytics
-keep class com.huawei.hms.utils.** { *; }

# Keep Huawei Base Adapter
-keep class com.huawei.hms.adapter.** { *; }
