# Daily Meal marketing README and preview APK design

## Goal

Turn the repository README into a Vietnamese marketing page for Daily Meal and
provide a direct GitHub download for an installable Android preview APK.

## Release artifact

- Build the current application as a Flutter debug APK.
- Publish it as a GitHub pre-release tagged `v1.0.0-preview`.
- Upload the asset as `daily-meal-v1.0.0-preview.apk`.
- Use the stable direct URL:
  `https://github.com/ngocthanhhx7/Daily_Meal_flutter_app/releases/download/v1.0.0-preview/daily-meal-v1.0.0-preview.apk`.
- Label the artifact clearly as a preview build, not a production release.

## README structure

1. Daily Meal logo and a concise product promise.
2. Primary call to action linking directly to the APK asset.
3. Product introduction focused on discovering, sharing, and discussing meals.
4. Feature highlights covering feeds, posts, profiles, search, messaging,
   notifications, premium experiences, and responsive Android/Web support.
5. Android installation instructions and platform requirements.
6. Preview limitations, including debug signing and potentially unavailable
   Facebook Login.
7. A compact developer section preserving essential setup, configuration,
   testing, build, architecture, and security notes from the current README.

## Safety and scope

- Do not generate or expose a production signing key.
- Do not present the debug APK as Play Store-ready or production-safe.
- Do not change Flutter application behavior or dependencies.
- Do not overwrite unrelated working-tree changes.
- Verify the build, APK existence, GitHub release asset, direct download URL,
  README links, and final Git status before completion.

## Success criteria

- The APK installs as an Android preview build.
- The GitHub pre-release contains the correctly named APK.
- The README direct-download button returns that APK.
- The README reads primarily as Vietnamese product marketing while retaining a
  concise developer reference.
