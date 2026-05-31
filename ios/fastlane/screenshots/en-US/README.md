# App Store Screenshots — English (en-US)

Place screenshot files here named: `01_<description>.png`, `02_<description>.png`, etc.

## Required device types and sizes

| Device class         | Resolution            | Notes                        |
|----------------------|-----------------------|------------------------------|
| iPhone 6.7" (Pro Max)| 1290×2796 px          | Required since iOS 16        |
| iPhone 6.5" (Plus)   | 1242×2688 px          | Older required size          |
| iPad 12.9" (Pro)     | 2048×2732 px          | Required if universal app    |

- Maximum 10 screenshots per device type.
- PNG or JPEG, RGB colour space, no alpha.
- Source screenshots are in `screenshots/` at the repo root — scale/crop to device sizes.

## App icon note
The 1024×1024 App Store icon is at `assets/icon/app_icon.png` in the repo root.
fastlane deliver picks it up from there; no need to copy it here.
