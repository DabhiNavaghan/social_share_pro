import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_share_pro/social_share_pro.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('social_share_pro');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'shareToFacebookStories') {
        throw PlatformException(code: 'FACEBOOK_NOT_INSTALLED');
      }
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('forwards app id and content url to the Instagram story share', () async {
    final ok = await SocialSharePro.shareToInstagramStories(
      stickerPath: '/tmp/sticker.png',
      backgroundTopColor: '#000000',
      backgroundBottomColor: '#FFFFFF',
      appId: '123',
      contentUrl: 'https://example.com/event',
    );

    expect(ok, isTrue);
    expect(calls.single.method, 'shareToInstagramStories');
    expect(calls.single.arguments, containsPair('appId', '123'));
    expect(calls.single.arguments, containsPair('contentUrl', 'https://example.com/event'));
  });

  test('returns false instead of throwing on a platform error', () async {
    final ok = await SocialSharePro.shareToFacebookStories(stickerPath: '/tmp/sticker.png', appId: '123');
    expect(ok, isFalse);
  });

  test('install checks call the matching method', () async {
    await SocialSharePro.isWhatsAppInstalled();
    expect(calls.single.method, 'isWhatsAppInstalled');
  });
}
