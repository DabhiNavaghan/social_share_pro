# social_share_pro

[![pub package](https://img.shields.io/pub/v/social_share_pro.svg)](https://pub.dev/packages/social_share_pro)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-lightgrey.svg)

Native story and status sharing for Flutter. Hand an image to **Instagram Stories**, **Facebook Stories**, **WhatsApp Status** or **Instagram Direct** and the user lands straight in the composer, with your sticker already on top of a background image or gradient. No `share_plus` sheet, no extra taps.

Built for apps that generate a branded card (an event ticket, a workout summary, a receipt, a quote) and want a one-tap "Add to Story" button.

## Features

| Feature | Android | iOS |
| --- | --- | --- |
| Instagram Stories: sticker + background image | ✅ | ✅ |
| Instagram Stories: sticker + colour gradient | ✅ | ✅ |
| Instagram Stories: Facebook App ID (`source_application`) | ✅ | ✅ |
| Instagram Stories: story link (`content_url`) | ✅ | ✅ |
| Facebook Stories: sticker + background image or gradient | ✅ | ✅ |
| Instagram Direct with prefilled text | ✅ | ✅ (clipboard fallback) |
| WhatsApp Status image | ✅ direct | ✅ via "Open in" menu |
| Save PNG to gallery | ✅ MediaStore | ✅ Photos, add-only |
| `isInstagramInstalled` / `isFacebookInstalled` / `isWhatsAppInstalled` | ✅ | ✅ |

Minimum versions: Android API 24, iOS 13.0, Flutter 3.13.

## Installation

```yaml
dependencies:
  social_share_pro: ^1.0.0
```

```sh
flutter pub get
```

### 1. Get a Facebook App ID

Meta requires a Facebook App ID for Stories sharing on both Instagram and Facebook. Without it the user sees *"The app you shared from doesn't currently support sharing to Stories."*

1. Create an app at <https://developers.facebook.com/apps>.
2. Copy the **App ID** from the dashboard. No review or extra products are needed for story sharing.

### 2. Android setup

**`android/app/src/main/AndroidManifest.xml`**

Add the package queries so Android 11+ lets your app see the target apps, and a `FileProvider` so the plugin can hand local files to them. The authority **must** be `<applicationId>.fileprovider`.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <queries>
        <package android:name="com.instagram.android" />
        <package android:name="com.facebook.katana" />
        <package android:name="com.whatsapp" />
    </queries>

    <application ...>

        <meta-data
            android:name="com.facebook.sdk.ApplicationId"
            android:value="@string/facebook_app_id" />

        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>

    </application>
</manifest>
```

**`android/app/src/main/res/xml/file_paths.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <cache-path name="cache" path="." />
    <files-path name="files" path="." />
    <external-path name="external" path="." />
    <external-files-path name="external_files" path="." />
</paths>
```

**`android/app/src/main/res/values/strings.xml`**

```xml
<resources>
    <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
</resources>
```

If you already use `flutter_facebook_auth` or another plugin that declares a `FileProvider`, keep a single provider and make sure its authority is `${applicationId}.fileprovider`.

### 3. iOS setup

**`ios/Runner/Info.plist`**

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>instagram</string>
    <string>instagram-stories</string>
    <string>facebook</string>
    <string>facebook-stories</string>
    <string>whatsapp</string>
</array>

<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>

<!-- Only if you call saveToGallery -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Saves your story image to Photos.</string>
```

The plugin ships a privacy manifest, so nothing else is needed for App Store privacy reporting.

## Usage

```dart
import 'package:social_share_pro/social_share_pro.dart';
```

Every method returns `Future<bool>`: `true` when the target app opened, `false` otherwise. The plugin never throws for a missing app, so you can call it from a button handler and show your own message on `false`.

### Instagram Stories with a gradient background

```dart
final ok = await SocialSharePro.shareToInstagramStories(
  stickerPath: cardFile.path,
  backgroundTopColor: '#1E1B4B',
  backgroundBottomColor: '#4C1D95',
  appId: facebookAppId,
);
if (!ok) showSnack('Instagram is not installed');
```

### Instagram Stories with a background image

```dart
await SocialSharePro.shareToInstagramStories(
  stickerPath: cardFile.path,
  backgroundImagePath: blurredBannerFile.path,
  appId: facebookAppId,
  contentUrl: 'https://example.com/events/summer-fest',
);
```

`contentUrl` is passed through to Instagram exactly as Meta's partner integrations do. Instagram currently renders it as a tappable link only for approved partner apps, so for everyone else it is harmless metadata. Follow the pattern below to still give your users a working link.

### Facebook Stories

```dart
await SocialSharePro.shareToFacebookStories(
  stickerPath: cardFile.path,
  backgroundTopColor: '#000000',
  backgroundBottomColor: '#000000',
  appId: facebookAppId,
);
```

### Instagram Direct

```dart
await SocialSharePro.shareToInstagramDirect(
  text: 'Join me at Summer Fest 🎶 https://example.com/events/summer-fest',
);
```

### WhatsApp Status

```dart
await SocialSharePro.shareToWhatsAppStatus(imagePath: compositeFile.path);
```

WhatsApp has no public status API. On Android the plugin opens WhatsApp's status picker directly. On iOS it shows the system "Open in" menu with WhatsApp listed, which is the most direct route Apple allows.

### Save to gallery

```dart
final bytes = await renderCardToPng();
await SocialSharePro.saveToGallery(
  imageBytes: bytes,
  fileName: 'summer_fest_story.png',
);
```

### Show only the buttons that work

```dart
final results = await Future.wait([
  SocialSharePro.isInstagramInstalled(),
  SocialSharePro.isFacebookInstalled(),
  SocialSharePro.isWhatsAppInstalled(),
]);
final canInstagram = results[0], canFacebook = results[1], canWhatsApp = results[2];
```

## Recipes

### Render a widget as the sticker

Wrap your card in a `RepaintBoundary`, capture it at 3x and write it to a temp file. A 640x480 logical card at 3x gives Instagram a crisp sticker.

```dart
final cardKey = GlobalKey();

// in build():
RepaintBoundary(key: cardKey, child: EventCard(event));

Future<File> captureCard() async {
  final boundary = cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3);
  final bytes = (await image.toByteData(format: ImageByteFormat.png))!.buffer.asUint8List();
  final file = File('${(await getTemporaryDirectory()).path}/story_card.png');
  return file.writeAsBytes(bytes);
}
```

### Blurred banner as the background

Downscale and blur the event banner into a 1080x1920 PNG so the composer looks designed rather than cropped.

```dart
Future<File> blurredBackground(Uint8List banner) async {
  final src = img.decodeImage(banner)!;
  final cover = img.copyResizeCropSquare(src, size: 1080);
  final tall = img.copyResize(cover, width: 1080, height: 1920);
  final blurred = img.gaussianBlur(tall, radius: 30);
  final file = File('${(await getTemporaryDirectory()).path}/story_bg.png');
  return file.writeAsBytes(img.encodePng(blurred));
}
```

### One-tap "Add to Story" with a working link

Because Instagram reserves tappable `content_url` for partners, copy the link to the clipboard right before opening Instagram and tell the user to add it with Instagram's **Link** sticker.

```dart
Future<void> addToStory(Event event) async {
  final sticker = await captureCard();
  final background = await blurredBackground(event.bannerBytes);

  await Clipboard.setData(ClipboardData(text: event.shareUrl));
  showSnack('Link copied. Paste it into the Link sticker in your story.');

  await SocialSharePro.shareToInstagramStories(
    stickerPath: sticker.path,
    backgroundImagePath: background.path,
    appId: facebookAppId,
    contentUrl: event.shareUrl,
  );
}
```

### Share sheet with analytics

```dart
Future<void> share(ShareTarget target) async {
  analytics.log('story_share', {'target': target.name});
  final sticker = await captureCard();
  final ok = switch (target) {
    ShareTarget.instagram => SocialSharePro.shareToInstagramStories(stickerPath: sticker.path, appId: facebookAppId),
    ShareTarget.facebook => SocialSharePro.shareToFacebookStories(stickerPath: sticker.path, appId: facebookAppId),
    ShareTarget.whatsapp => SocialSharePro.shareToWhatsAppStatus(imagePath: sticker.path),
  };
  if (!await ok) analytics.log('story_share_failed', {'target': target.name});
}
```

## Asset guidelines

Meta's recommendations, which the composer handles best:

| Asset | Format | Size |
| --- | --- | --- |
| Sticker | PNG or JPG | 640x480 recommended |
| Background image | PNG or JPG | at least 720x1280, 9:16 |
| Colours | hex string | `#RRGGBB`, defaults to `#FFFFFF` for Instagram and `#000000` for Facebook |

Background colours are ignored whenever a background image is supplied.

## API

| Method | Returns | Notes |
| --- | --- | --- |
| `shareToInstagramStories({stickerPath, backgroundImagePath, backgroundTopColor, backgroundBottomColor, appId, contentUrl})` | `Future<bool>` | `stickerPath` required |
| `shareToFacebookStories({stickerPath, backgroundImagePath, backgroundTopColor, backgroundBottomColor, appId})` | `Future<bool>` | `appId` required by Facebook |
| `shareToInstagramDirect({text})` | `Future<bool>` | |
| `shareToWhatsAppStatus({imagePath})` | `Future<bool>` | |
| `saveToGallery({imageBytes, fileName})` | `Future<bool>` | PNG bytes |
| `isInstagramInstalled()` / `isFacebookInstalled()` / `isWhatsAppInstalled()` | `Future<bool>` | |

## Troubleshooting

**"The app you shared from doesn't currently support sharing to Stories"**
Pass `appId` and make sure the same ID is in `Info.plist` (`FacebookAppID`) and the Android manifest (`com.facebook.sdk.ApplicationId`).

**`FileProvider` / `IllegalArgumentException: Failed to find configured root`** on Android
The file lives outside the paths listed in `file_paths.xml`. Write it to the temporary or application documents directory, or add the matching `<*-path>` entry.

**`isInstagramInstalled()` returns `false` on iOS although Instagram is installed**
`instagram-stories` is missing from `LSApplicationQueriesSchemes`.

**The story opens but the sticker is missing**
The sticker file must be PNG or JPG and under a few MB. Capture with `pixelRatio: 3` rather than higher.

**`contentUrl` does nothing**
Expected unless Meta has approved your app for link attribution. Use the clipboard plus Link sticker recipe above.

## Example

The `example/` app lets you pick an image and share it to each target. Set your Facebook App ID in `example/lib/main.dart` first.

## Contributing

Issues and pull requests are welcome at <https://github.com/DabhiNavaghan/social_share_pro>.

## License

MIT © Navaghan Dabhi
