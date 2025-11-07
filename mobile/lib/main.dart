import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rapid_photo_mobile/features/gallery/widgets/gallery_screen.dart';
import 'package:rapid_photo_mobile/features/upload/widgets/upload_screen.dart';
import 'package:rapid_photo_mobile/shared/auth/amplify_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: RapidPhotoApp(),
    ),
  );
}

class RapidPhotoApp extends StatelessWidget {
  const RapidPhotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RapidPhoto Upload',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('RapidPhoto Upload'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.photo_library,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to RapidPhoto Upload',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Flutter 3.27 Mobile App',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Text(
              'Features:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('• Upload up to 100 photos concurrently'),
            const Text('• Gallery with infinite scroll'),
            const Text('• AI-powered tag search'),
            const Text('• Download and share photos'),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _navigateToUpload(context, ref),
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Go to Upload'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _navigateToGallery(context, ref),
              icon: const Icon(Icons.photo_library),
              label: const Text('View Gallery'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToUpload(BuildContext context, WidgetRef ref) async {
    // Initialize Amplify before navigating
    final authService = ref.read(amplifyAuthServiceProvider);
    try {
      await authService.configure();
    } catch (e) {
      // Amplify might already be configured
    }

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UploadScreen(),
      ),
    );
  }

  Future<void> _navigateToGallery(BuildContext context, WidgetRef ref) async {
    // Initialize Amplify before navigating
    final authService = ref.read(amplifyAuthServiceProvider);
    try {
      await authService.configure();
    } catch (e) {
      // Amplify might already be configured
    }

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GalleryScreen(),
      ),
    );
  }
}
