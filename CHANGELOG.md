## 1.0.0

Initial release.

* Share an image sticker to **Instagram Stories** with a background image or a top/bottom colour gradient.
* Pass your Facebook App ID (`appId`) as `source_application`, required by Meta since January 2023.
* Optional `contentUrl` forwarded as `content_url` / `com.instagram.sharedSticker.contentURL`.
* Share an image sticker to **Facebook Stories** with background image or gradient.
* Open **Instagram Direct** with prefilled text, with clipboard fallback on iOS.
* Share an image to **WhatsApp Status**.
* Save PNG bytes to the device **gallery** (MediaStore on Android, Photos on iOS with add-only permission).
* `isInstagramInstalled`, `isFacebookInstalled`, `isWhatsAppInstalled` helpers.
* Android package `dev.navaghandabhi.social_share_pro`, minSdk 24. iOS 13.0+.
