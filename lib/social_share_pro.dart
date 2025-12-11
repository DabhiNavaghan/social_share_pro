import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class SocialSharePro {
  static const MethodChannel _channel = MethodChannel('social_share_pro');

  /// Share to Instagram Stories
  static Future<bool> shareToInstagramStories({
    required String stickerPath,
    String? backgroundImagePath,
    String? backgroundTopColor,
    String? backgroundBottomColor,
  }) async {
    final Map<String, dynamic> args = {
      'stickerPath': stickerPath,
      'backgroundImagePath': backgroundImagePath,
      'backgroundTopColor': backgroundTopColor,
      'backgroundBottomColor': backgroundBottomColor,
    };
    try {
      final result = await _channel.invokeMethod<bool>('shareToInstagramStories', args);
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Share to Facebook Stories
  static Future<bool> shareToFacebookStories({
    required String stickerPath,
    String? backgroundImagePath,
    String? backgroundTopColor,
    String? backgroundBottomColor,
    String? appId,
  }) async {
    final Map<String, dynamic> args = {
      'stickerPath': stickerPath,
      'backgroundImagePath': backgroundImagePath,
      'backgroundTopColor': backgroundTopColor,
      'backgroundBottomColor': backgroundBottomColor,
      'appId': appId,
    };
    try {
      final result = await _channel.invokeMethod<bool>('shareToFacebookStories', args);
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Share to WhatsApp Status
  static Future<bool> shareToWhatsAppStatus({
    required String imagePath,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('shareToWhatsAppStatus', {'imagePath': imagePath});
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Save image to Gallery
  static Future<bool> saveToGallery({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('saveToGallery', {
        'imageBytes': imageBytes,
        'fileName': fileName,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Check if Instagram is installed
  static Future<bool> isInstagramInstalled() async {
    try {
      return await _channel.invokeMethod<bool>('isInstagramInstalled') ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Check if Facebook is installed
  static Future<bool> isFacebookInstalled() async {
    try {
      return await _channel.invokeMethod<bool>('isFacebookInstalled') ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Check if WhatsApp is installed
  static Future<bool> isWhatsAppInstalled() async {
    try {
      return await _channel.invokeMethod<bool>('isWhatsAppInstalled') ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
