# Daily Meal Assets and Design Tokens

## Asset Inventory

Source root: `D:\WW\Daily_Meal_App\daily_meal\client\assets`

| Format | Count | Flutter handling |
|---|---:|---|
| SVG | 272 | Use `flutter_svg`; preserve vector source and semantic labels for interactive icons |
| PNG | 40 | Copy branded raster assets with original resolution; use Flutter resolution variants only when source variants exist |
| JPG | 1 | Preserve as authored sticker/photo asset |
| TTF | 4 | Register Work Sans weights in `pubspec.yaml` |
| OTF | 18 | Inventory font-text/design sources; only bundle weights actually used by production UI |
| AI | 1 | Design source only; do not bundle in runtime assets |
| MD | 1 | Read licensing/attribution instructions before copying assets |

Primary groups:

- `assets/logo`: Daily Meal logo, square app icon and vector design source
- `assets/icons/Dark` and `assets/icons/White`: UI icon library
- `assets/feed`: feed background/food/author/streak artwork
- `assets/stickers`: OpenMoji/custom sticker assets
- `assets/figma-snapshots`: visual references, not runtime dependencies unless source code uses them

Before copying any group, verify actual imports with `rg` and record its target path in the parity matrix. Do not bundle unused icon families.

## Color Tokens

Source: `client/src/theme/colors.ts:1-15`.

| Token | Value | Material role guidance |
|---|---|---|
| ink | `#202124` | onSurface/onBackground |
| muted | `#74746F` | onSurfaceVariant |
| line | `#E4E1D8` | outlineVariant |
| surface | `#FFFFFF` | surface |
| canvas | `#F4F3EF` | background/surfaceContainerLowest |
| canvasStrong | `#ECE9DF` | surfaceContainer |
| green | `#8BA58A` | primary |
| greenDark | `#4F6F3D` | primaryContainer emphasis/onPrimaryContainer candidate |
| yellow | `#F6DE68` | tertiary/accent |
| red | `#E65B55` | error/destructive |
| black | `#0D0D0D` | high-emphasis content |
| white | `#FFFFFF` | inverse/on-dark content |
| blue | `#65A9D7` | informational/link accent |

Material role assignments must be contrast-tested rather than copied blindly.

## Spacing

Source: `client/src/theme/spacing.ts:1-8`.

| Token | dp |
|---|---:|
| xs | 4 |
| sm | 8 |
| md | 12 |
| lg | 16 |
| xl | 24 |
| xxl | 32 |

Use these as the base scale; responsive outer gutters may use 40/48dp where wide layouts require it.

## Typography

Source: `client/src/theme/typography.ts:1-6`.

- Family: Work Sans
- Regular: `WorkSans-Regular`
- Medium: `WorkSans-Medium`
- Semibold: `WorkSans-Semibold`
- Bold: `WorkSans-Bold`

Map the existing hierarchy to Material 3 `TextTheme`, preserve Vietnamese glyph coverage and test text scaling at 100%, 130% and 200%.

## Responsive Rules

| Width/reference | Navigation/layout |
|---|---|
| 360×800 | Bottom navigation, stack pages and modal bottom sheets |
| 600×1024 | Adaptive rail/drawer; two-pane layout only where it improves task continuity |
| 1024×768 | Tablet/narrow-Web layout with bounded content width |
| 1440×900 | Centered user content; admin sidebar, chart grid and data tables |

Admin tables must become cards/lists on narrow screens without losing filters, pagination or row actions. Minimum interactive target is 48dp. Web requires visible focus, keyboard navigation and hover feedback. Motion honors reduced-motion settings.

## Asset Acceptance

- No runtime reference to `.ai` or design-only snapshots.
- No broken SVG rendering on Android/Web.
- App icon/splash preserve Daily Meal logo and `#F4F3EF` canvas.
- Every bundled font and asset is declared once and used.
- Attribution/licensing notes are retained when required.
