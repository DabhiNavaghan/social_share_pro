import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_share_pro/social_share_pro.dart';

const facebookAppId = 'YOUR_FACEBOOK_APP_ID';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Share Pro',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const ShareScreen(),
    );
  }
}

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _picker = ImagePicker();
  final _linkController = TextEditingController(text: 'https://example.com/events/summer-fest');
  bool _instagram = false;
  bool _facebook = false;
  bool _whatsapp = false;

  @override
  void initState() {
    super.initState();
    _refreshInstalledApps();
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _refreshInstalledApps() async {
    final results = await Future.wait([
      SocialSharePro.isInstagramInstalled(),
      SocialSharePro.isFacebookInstalled(),
      SocialSharePro.isWhatsAppInstalled(),
    ]);
    if (!mounted) return;
    setState(() {
      _instagram = results[0];
      _facebook = results[1];
      _whatsapp = results[2];
    });
  }

  Future<String?> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    return file?.path;
  }

  void _report(bool ok, String target) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Opened $target' : 'Could not open $target')));
  }

  Future<void> _instagramGradient() async {
    final sticker = await _pickImage();
    if (sticker == null) return;
    final ok = await SocialSharePro.shareToInstagramStories(
      stickerPath: sticker,
      backgroundTopColor: '#1E1B4B',
      backgroundBottomColor: '#4C1D95',
      appId: facebookAppId,
      contentUrl: _linkController.text,
    );
    _report(ok, 'Instagram Stories');
  }

  Future<void> _instagramBackground() async {
    final sticker = await _pickImage();
    if (sticker == null) return;
    final background = await _pickImage();
    if (background == null) return;
    await Clipboard.setData(ClipboardData(text: _linkController.text));
    final ok = await SocialSharePro.shareToInstagramStories(
      stickerPath: sticker,
      backgroundImagePath: background,
      appId: facebookAppId,
      contentUrl: _linkController.text,
    );
    _report(ok, 'Instagram Stories');
  }

  Future<void> _instagramDirect() async {
    final ok = await SocialSharePro.shareToInstagramDirect(text: 'Check this out: ${_linkController.text}');
    _report(ok, 'Instagram Direct');
  }

  Future<void> _facebookStories() async {
    final sticker = await _pickImage();
    if (sticker == null) return;
    final ok = await SocialSharePro.shareToFacebookStories(
      stickerPath: sticker,
      backgroundTopColor: '#000000',
      backgroundBottomColor: '#000000',
      appId: facebookAppId,
    );
    _report(ok, 'Facebook Stories');
  }

  Future<void> _whatsAppStatus() async {
    final image = await _pickImage();
    if (image == null) return;
    final ok = await SocialSharePro.shareToWhatsAppStatus(imagePath: image);
    _report(ok, 'WhatsApp Status');
  }

  Future<void> _saveToGallery() async {
    final image = await _pickImage();
    if (image == null) return;
    final bytes = await XFile(image).readAsBytes();
    final ok = await SocialSharePro.saveToGallery(imageBytes: bytes, fileName: 'social_share_${DateTime.now().millisecondsSinceEpoch}.png');
    _report(ok, 'gallery');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Share Pro'),
        actions: [IconButton(onPressed: _refreshInstalledApps, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              _InstalledChip(label: 'Instagram', installed: _instagram),
              _InstalledChip(label: 'Facebook', installed: _facebook),
              _InstalledChip(label: 'WhatsApp', installed: _whatsapp),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _linkController,
            decoration: const InputDecoration(labelText: 'Story link', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          _Section(title: 'Instagram', children: [
            FilledButton.icon(onPressed: _instagram ? _instagramGradient : null, icon: const Icon(Icons.gradient), label: const Text('Story with gradient')),
            FilledButton.icon(onPressed: _instagram ? _instagramBackground : null, icon: const Icon(Icons.image), label: const Text('Story with background image')),
            OutlinedButton.icon(onPressed: _instagram ? _instagramDirect : null, icon: const Icon(Icons.send), label: const Text('Direct message')),
          ]),
          _Section(title: 'Facebook', children: [
            FilledButton.icon(onPressed: _facebook ? _facebookStories : null, icon: const Icon(Icons.auto_stories), label: const Text('Story')),
          ]),
          _Section(title: 'WhatsApp', children: [
            FilledButton.icon(onPressed: _whatsapp ? _whatsAppStatus : null, icon: const Icon(Icons.chat), label: const Text('Status')),
          ]),
          _Section(title: 'Device', children: [
            OutlinedButton.icon(onPressed: _saveToGallery, icon: const Icon(Icons.download), label: const Text('Save to gallery')),
          ]),
        ],
      ),
    );
  }
}

class _InstalledChip extends StatelessWidget {
  final String label;
  final bool installed;

  const _InstalledChip({required this.label, required this.installed});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(installed ? Icons.check_circle : Icons.cancel, size: 18, color: installed ? Colors.green : Colors.grey),
      label: Text(label),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final child in children) Padding(padding: const EdgeInsets.only(bottom: 8), child: child),
        ],
      ),
    );
  }
}
