# Google Play Store Image Assets

Place the following files in the subdirectories listed below.
supply (fastlane) uploads them automatically when `skip_upload_images: false`.

## Required assets and sizes

| Directory          | Filename(s)          | Size / format                                    |
|--------------------|----------------------|--------------------------------------------------|
| `icon/`            | `icon.png`           | 512×512 px, PNG, 32-bit (with transparency OK)   |
| `featureGraphic/`  | `featureGraphic.png` | 1024×500 px, PNG or JPG, max 1 MB                |
| `phoneScreenshots/`| `01.png` … `08.png`  | Min 320px on shortest side, max 3840px, max 8 MB |
|                    |                      | Accepted ratios: 16:9 or 9:16 (portrait/landscape)|

## Notes
- The launcher icon is already generated under `android/app/src/main/res/`.
  Export a 512×512 copy here for the Play Store listing icon slot.
- Screenshots must be taken from a real or emulated device.
  The existing screenshots in `screenshots/` at the repo root are good
  starting points — resize/crop to Play Store specs.
- featureGraphic is shown on the Play Store app page header.
  Recommended: emerald/gold theme banner with app name "Quiz Sîra" (no figurative imagery).
