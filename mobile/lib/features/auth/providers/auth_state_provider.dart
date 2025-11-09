import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:rapid_photo_mobile/shared/auth/amplify_auth_service.dart';

/// Auth state model
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final bool isLoading;

  const AuthState({
    required this.isAuthenticated,
    this.userId,
    this.email,
    required this.isLoading,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? email,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Auth state notifier
class AuthStateNotifier extends Notifier<AuthState> {
  final Logger _logger = Logger();
  late final AmplifyAuthService _authService;

  @override
  AuthState build() {
    _authService = ref.watch(amplifyAuthServiceProvider);
    _checkAuthStatus();
    _listenToAuthEvents();
    return const AuthState(isAuthenticated: false, isLoading: true);
  }

  /// Check initial auth status
  Future<void> _checkAuthStatus() async {
    try {
      _logger.i('Checking auth status...');
      final isSignedIn = await _authService.isSignedIn();
      _logger.i('Is signed in: $isSignedIn');

      if (isSignedIn) {
        final userId = await _authService.getCurrentUserId();
        final attributes = await Amplify.Auth.fetchUserAttributes();
        final emailAttr = attributes.firstWhere(
          (attr) => attr.userAttributeKey == AuthUserAttributeKey.email,
          orElse: () => const AuthUserAttribute(
            userAttributeKey: AuthUserAttributeKey.email,
            value: '',
          ),
        );

        _logger.i('User authenticated: $userId, ${emailAttr.value}');
        state = AuthState(
          isAuthenticated: true,
          userId: userId,
          email: emailAttr.value,
          isLoading: false,
        );
      } else {
        _logger.i('User not authenticated, showing login');
        state = const AuthState(
          isAuthenticated: false,
          isLoading: false,
        );
      }
    } catch (e) {
      _logger.e('Error checking auth status: $e');
      print('AUTH ERROR: $e');
      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
      );
    }
  }

  /// Listen to auth events (sign in, sign out, etc.)
  void _listenToAuthEvents() {
    Amplify.Hub.listen(HubChannel.Auth, (event) {
      switch (event.eventName) {
        case 'SIGNED_IN':
          _handleSignIn();
          break;
        case 'SIGNED_OUT':
          _handleSignOut();
          break;
        case 'SESSION_EXPIRED':
          _handleSignOut();
          break;
      }
    });

    _logger.i('Auth event listener started');
  }

  /// Handle sign in event
  Future<void> _handleSignIn() async {
    try {
      final userId = await _authService.getCurrentUserId();
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final emailAttr = attributes.firstWhere(
        (attr) => attr.userAttributeKey == AuthUserAttributeKey.email,
        orElse: () => const AuthUserAttribute(
          userAttributeKey: AuthUserAttributeKey.email,
          value: '',
        ),
      );

      state = AuthState(
        isAuthenticated: true,
        userId: userId,
        email: emailAttr.value,
        isLoading: false,
      );
    } catch (e) {
      _logger.e('Error handling sign in: $e');
    }
  }

  /// Handle sign out event
  void _handleSignOut() {
    state = const AuthState(
      isAuthenticated: false,
      isLoading: false,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
      );
    } catch (e) {
      _logger.e('Error signing out: $e');
      rethrow;
    }
  }

  /// Refresh auth state
  Future<void> refresh() async {
    await _checkAuthStatus();
  }
}

/// Provider for auth state
final authStateProvider = NotifierProvider<AuthStateNotifier, AuthState>(() {
  return AuthStateNotifier();
});

/// Provider for JWT token
final jwtTokenProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(amplifyAuthServiceProvider);
  return authService.getJwtToken();
});
