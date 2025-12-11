import 'package:flutter/material.dart';
import 'package:social_share_pro/social_share_pro.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndShareToInstagram() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await SocialSharePro.shareToInstagramStories(
        stickerPath: image.path,
        backgroundTopColor: "#FF0000",
        backgroundBottomColor: "#0000FF",
      );
    }
  }

  Future<void> _pickAndShareToFacebook() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // You need a valid Facebook App ID here
      await SocialSharePro.shareToFacebookStories(
        stickerPath: image.path,
        appId: 'YOUR_FACEBOOK_APP_ID',
        backgroundTopColor: "#00FF00",
        backgroundBottomColor: "#FFFF00",
      );
    }
  }
  
  Future<void> _pickAndShareToWhatsApp() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await SocialSharePro.shareToWhatsAppStatus(
        imagePath: image.path,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Social Share Pro Example'),
        ),
        body: Center(
          child: Column(
            children: [
               const SizedBox(height: 20),
               ElevatedButton(
                 onPressed: _pickAndShareToInstagram,
                 child: const Text("Share to Instagram Stories"),
               ),
               ElevatedButton(
                 onPressed: _pickAndShareToFacebook,
                 child: const Text("Share to Facebook Stories"),
               ),
               ElevatedButton(
                 onPressed: _pickAndShareToWhatsApp,
                 child: const Text("Share to WhatsApp Status"),
               ),
            ],
          ),
        ),
      ),
    );
  }
}
