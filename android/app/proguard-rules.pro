# Chronos – additional R8 rules for release builds.
#
# The Flutter Gradle plugin already applies proguard-android-optimize.txt and Flutter's own rules,
# and every plugin ships its consumer rules (Gson, used by flutter_local_notifications >= 19,
# brings its rules itself). Only app-specific additions belong here.

# flutter_local_notifications stores scheduled notifications (the "Arbeitest du noch?" reminder)
# as Gson JSON in SharedPreferences and reads them back after a reboot or an app update
# (ScheduledNotificationBootReceiver). Gson maps JSON keys to field names and uses class names
# for the style subtypes, so these names must not be obfuscated: otherwise a reminder stored by
# one release could not be read by the next one.
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keepattributes Signature
