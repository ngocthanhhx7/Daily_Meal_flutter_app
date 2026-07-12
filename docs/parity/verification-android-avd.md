# Android AVD runtime verification

Date: 2026-07-12

## Environment

- AVD definition: `D:\Android\AVD\Medium_Phone.avd`
- Target: Android 36.1 Google Play, x86_64, 1080 x 2400 at density 420
- Device reported by adb: `emulator-5554`, `sdk_gphone64_x86_64`
- Package: `com.dailymeal.daily_meal_app`

## Runtime evidence

The production-defined debug APK was installed through adb. After clearing app
data, `am start -W` reported a successful cold launch and MainActivity became
the focused/resumed activity. The clean login screen rendered without overflow
at the AVD resolution.

The Android accessibility hierarchy exposed:

- root label `Daily Meal application`;
- email/phone mode controls;
- email and password editors;
- login, password recovery, Google, Facebook, registration and Admin actions;
- 126-pixel-high action bounds at density 420, consistent with the Material
  minimum touch-target policy.

Using only synthetic input, an invalid email submission rendered the localized
email-format error in the accessibility tree and did not expose Dio or internal
host details. Navigation to the dedicated Admin login screen succeeded; its
admin email/password editors, login action and return action were accessible.

## Android Facebook configuration finding

Initial AVD logcat showed that a missing Meta App ID caused
`FacebookInitProvider` and `GeneratedPluginRegistrant` failures. This can block
registration of unrelated Flutter plugins.

Android now supplies the public App ID, URL scheme, Meta activities and package
visibility through manifest/resources. Debug builds can boot with an explicit
invalid Client Token marker for non-Facebook smoke testing; release builds fail
fast until `android/facebook.properties`, environment variables or Gradle
properties provide the real Meta Client Token. A subsequent clean cold launch
had no `FacebookInitProvider` or `GeneratedPluginRegistrant` failure.

Live Facebook login remains unverified because the production Meta Client
Token and matching debug/release key hashes were not supplied. Debug logcat
correctly shows Meta rejecting the invalid marker rather than silently treating
Facebook login as configured.

## AVD caveat

The first emulator boot produced a System UI ANR while Android initialized the
Google Play image and software renderer. Selecting `Wait` allowed the app to
render, and later clean launches reached MainActivity. This was an emulator
System UI condition, not an application process crash; no Flutter fatal
exception was recorded.
