# Slice 4 Create Post Verification

Verification date: 2026-07-11

## Automated evidence

Fresh checks with production dart-defines completed successfully:

- `flutter test`: 103 tests passed.
- `flutter analyze`: no issues found.
- `flutter build web --release`: exit 0, artifact `build/web`, Wasm dry run passed.
- `flutter build apk --debug`: exit 0, artifact
  `build/app/outputs/flutter-apk/app-debug.apk`.

## Proven behavior

- Android/Web media adapter based on `image_picker`, byte-oriented processing
  and MIME detection independent of mobile filesystem assumptions.
- Client validation matches server image 8 MB, video 50 MB, supported MIME and
  30-second duration boundaries.
- Free account one-image limit; Premium three-image or one-video capability.
- Exact multipart `image`/`video` field and `category=post` query contract.
- Exact AI `{uploadId, hints: {ingredientsText}}` contract and typed meal result.
- Upload reuse between analysis and publish, per-image nutrition detail mapping.
- Full create payload for layout/transforms, caption/tags, recipes, nutrition,
  sticker placement and visibility.
- Draft remains intact after publish failure and can be retried.
- Responsive composer route with gallery/camera/video, preview, AI, recipe,
  privacy/layout and sticker drag/scale/rotation controls.

## Evidence boundary

No mock is treated as proof that external capabilities are live. Required manual
evidence remains: physical Android camera/gallery permission flows, Web browser
file chooser behavior, live production upload/AI latency and failures, video
duration metadata across device formats, and Premium custom sticker creation.
Edit/delete post are not part of this create-only checkpoint and remain open.

## Android environment warning

The known Kotlin cross-drive incremental-cache warning occurred while compiling
`image_picker_android` (`C:` Pub cache versus `D:` workspace). Gradle recovered,
returned exit 0 and produced the APK.
