import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rapid_photo_mobile/features/auth/providers/auth_state_provider.dart';
import 'package:rapid_photo_mobile/features/auth/widgets/login_screen.dart';
import 'package:rapid_photo_mobile/features/gallery/widgets/gallery_screen.dart';
import 'package:rapid_photo_mobile/features/upload/widgets/upload_screen.dart';
import 'package:rapid_photo_mobile/shared/auth/amplify_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Amplify
  final authService = AmplifyAuthService();
  try {
    await authService.configure();
  } catch (e) {
    // Amplify already configured or error
    print('Amplify configuration: $e');
  }

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
    // Watch auth state
    final authState = ref.watch(authStateProvider);

    // Debug logging
    print('Auth State - isLoading: ${authState.isLoading}, isAuthenticated: ${authState.isAuthenticated}, email: ${authState.email}');

    // Show loading while checking auth
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show login screen if not authenticated
    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    // Show main app if authenticated
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('RapidPhoto Upload'),
        actions: [
          // Show user email and sign out button
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  authState.email ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'signout',
                child: const Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'signout') {
                await ref.read(authStateProvider.notifier).signOut();
              }
            },
          ),
        ],
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
            Text(
              'Signed in as ${authState.email ?? "User"}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
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
              onPressed: () => _navigateToUpload(context),
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Go to Upload'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _navigateToGallery(context),
              icon: const Icon(Icons.photo_library),
              label: const Text('View Gallery'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToUpload(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UploadScreen(),
      ),
    );
  }

  void _navigateToGallery(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GalleryScreen(),
      ),
    );
  }
}
