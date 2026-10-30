import 'dart:async';

import 'package:flutter/services.dart';

/// Shares images to Instagram Stories, Facebook Stories, WhatsApp Status and
/// Instagram Direct, and saves images to the device gallery.
///
/// Every share method returns `true` when the target app was opened and
/// `false` when it was not (app missing, invalid arguments or a platform
/// error). Use the `is*Installed` helpers to decide which buttons to show.
///
/// All file paths must point to local files readable by the app, for example
/// a file written to the temporary directory. On Android the host app must
/// declare a `FileProvider` with the authority `<applicationId>.fileprovider`
/// so the file can be handed to the target app. See the README for setup.
class SocialSharePro {
  SocialSharePro._();

  static const MethodChannel _channel = MethodChannel('social_share_pro');

  /// Opens the Instagram story composer with [stickerPath] as the sticker layer.
  ///
  /// Pass [backgroundImagePath] to use a full screen image behind the sticker,
  /// or [backgroundTopColor] and [backgroundBottomColor] (hex, e.g. `#FF5500`)
  /// to render a gradient. Both colours equal produce a solid background.
  /// When a background image is set the colours are ignored.
  ///
  /// [appId] is your Facebook App ID. Meta requires it for story sharing;
  /// without it Instagram shows "The app you shared from doesn't currently
  /// support sharing to Stories." On iOS it falls back to the bundle
  /// identifier when omitted.
  ///
  /// [contentUrl] is forwarded as `content_url` (Android) and
  /// `com.instagram.sharedSticker.contentURL` (iOS). Instagram only renders it
  /// as a tappable link for apps with a Meta partnership, so treat it as
  /// optional metadata rather than a guaranteed link.
  ///
  /// Recommended sticker size is 640x480 and background 1080x1920.
  static Future<bool> shareToInstagramStories({
    required String stickerPath,
    String? backgroundImagePath,
    String? backgroundTopColor,
    String? backgroundBottomColor,
    String? appId,
    String? contentUrl,
  }) {
    return _invoke('shareToInstagramStories', {
      'stickerPath': stickerPath,
      'backgroundImagePath': backgroundImagePath,
      'backgroundTopColor': backgroundTopColor,
      'backgroundBottomColor': backgroundBottomColor,
      'appId': appId,
      'contentUrl': contentUrl,
    });
  }

  /// Opens Instagram Direct with [text] ready to send.
  ///
  /// Android uses a plain text `ACTION_SEND` targeted at Instagram. iOS uses
  /// the `instagram://sharesheet` scheme and, if that fails, copies [text] to
  /// the clipboard, opens Instagram and shows a short hint.
  static Future<bool> shareToInstagramDirect({required String text}) {
    return _invoke('shareToInstagramDirect', {'text': text});
  }

  /// Opens the Facebook story composer with [stickerPath] as the sticker layer.
  ///
  /// [appId] is your Facebook App ID and is required by Facebook. Background
  /// options behave the same as in [shareToInstagramStories].
  static Future<bool> shareToFacebookStories({
    required String stickerPath,
    String? backgroundImagePath,
    String? backgroundTopColor,
    String? backgroundBottomColor,
    String? appId,
  }) {
    return _invoke('shareToFacebookStories', {
      'stickerPath': stickerPath,
      'backgroundImagePath': backgroundImagePath,
      'backgroundTopColor': backgroundTopColor,
      'backgroundBottomColor': backgroundBottomColor,
      'appId': appId,
    });
  }

  /// Shares the image at [imagePath] to WhatsApp Status.
  ///
  /// Android opens WhatsApp's status picker directly. iOS presents the system
  /// "Open in" menu with WhatsApp listed, because WhatsApp exposes no direct
  /// status scheme on iOS.
  static Future<bool> shareToWhatsAppStatus({required String imagePath}) {
    return _invoke('shareToWhatsAppStatus', {'imagePath': imagePath});
  }

  /// Saves PNG [imageBytes] to the gallery as [fileName].
  ///
  /// Android writes to `Pictures/SocialShare` through MediaStore and needs no
  /// runtime permission on API 29+. iOS adds the image to Photos and requests
  /// add-only access, so `NSPhotoLibraryAddUsageDescription` must be set.
  static Future<bool> saveToGallery({
    required Uint8List imageBytes,
    required String fileName,
  }) {
    return _invoke('saveToGallery', {
      'imageBytes': imageBytes,
      'fileName': fileName,
    });
  }

  /// Whether Instagram is installed and reachable from this app.
  static Future<bool> isInstagramInstalled() => _invoke('isInstagramInstalled');

  /// Whether Facebook is installed and reachable from this app.
  static Future<bool> isFacebookInstalled() => _invoke('isFacebookInstalled');

  /// Whether WhatsApp is installed and reachable from this app.
  static Future<bool> isWhatsAppInstalled() => _invoke('isWhatsAppInstalled');

  static Future<bool> _invoke(String method, [Map<String, dynamic>? args]) async {
    try {
      return await _channel.invokeMethod<bool>(method, args) ?? false;
    } on PlatformException {
      return false;
    }
  }
}
