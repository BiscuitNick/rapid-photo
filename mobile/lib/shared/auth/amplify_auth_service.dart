import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Amplify Auth Service for managing authentication and storage
class AmplifyAuthService {
  final Logger _logger = Logger();
  bool _isConfigured = false;

  /// Check if Amplify is configured
  bool get isConfigured => _isConfigured;

  /// Configure Amplify with Auth and Storage
  Future<void> configure() async {
    if (_isConfigured) {
      _logger.i('Amplify already configured');
      return;
    }

    try {
      // Add Amplify plugins
      await Amplify.addPlugins([
        AmplifyAuthCognito(),
        AmplifyStorageS3(),
      ]);

      // Configure Amplify with the configuration
      // Note: In production, this would use amplifyconfig.json
      // For now, we'll configure it programmatically
      await Amplify.configure(_amplifyConfig);

      _isConfigured = true;
      _logger.i('Amplify configured successfully');
    } on AmplifyAlreadyConfiguredException {
      _logger.i('Amplify was already configured');
      _isConfigured = true;
    } catch (e) {
      _logger.e('Failed to configure Amplify: $e');
      rethrow;
    }
  }

  /// Get current user session
  Future<AuthSession> getCurrentSession() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session;
    } catch (e) {
      _logger.e('Failed to get current session: $e');
      rethrow;
    }
  }

  /// Get JWT token
  Future<String?> getJwtToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession(
        options: const FetchAuthSessionOptions(
          forceRefresh: false,
        ),
      ) as CognitoAuthSession;

      return session.userPoolTokensResult.value.idToken.raw;
    } catch (e) {
      _logger.e('Failed to get JWT token: $e');
      return null;
    }
  }

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final subAttribute = attributes.firstWhere(
        (attr) => attr.userAttributeKey == CognitoUserAttributeKey.sub,
      );
      return subAttribute.value;
    } catch (e) {
      _logger.e('Failed to get user ID: $e');
      return null;
    }
  }

  /// Sign in with username and password
  Future<SignInResult> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: username,
        password: password,
      );
      return result;
    } catch (e) {
      _logger.e('Failed to sign in: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Failed to sign out: $e');
      rethrow;
    }
  }

  /// Check if user is signed in
  Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } catch (e) {
      _logger.e('Failed to check sign-in status: $e');
      return false;
    }
  }

  /// Amplify configuration
  /// In production, this would be loaded from amplifyconfig.json
  /// This is a placeholder configuration for development
  static const String _amplifyConfig = '''
{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/0.1.0",
        "Version": "0.1.0",
        "IdentityManager": {
          "Default": {}
        },
        "CredentialsProvider": {
          "CognitoIdentity": {
            "Default": {
              "PoolId": "us-east-1:placeholder-pool-id",
              "Region": "us-east-1"
            }
          }
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-1_placeholder",
            "AppClientId": "placeholder-client-id",
            "Region": "us-east-1"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH",
            "socialProviders": [],
            "usernameAttributes": ["EMAIL"],
            "signupAttributes": ["EMAIL"],
            "passwordProtectionSettings": {
              "passwordPolicyMinLength": 8,
              "passwordPolicyCharacters": []
            },
            "mfaConfiguration": "OFF",
            "mfaTypes": ["SMS"],
            "verificationMechanisms": ["EMAIL"]
          }
        }
      }
    }
  },
  "storage": {
    "plugins": {
      "awsS3StoragePlugin": {
        "bucket": "rapid-photo-uploads-placeholder",
        "region": "us-east-1",
        "defaultAccessLevel": "private"
      }
    }
  }
}
''';
}

/// Provider for AmplifyAuthService
final amplifyAuthServiceProvider = Provider<AmplifyAuthService>((ref) {
  return AmplifyAuthService();
});

/// Provider for current auth session
final authSessionProvider = FutureProvider<AuthSession>((ref) async {
  final authService = ref.watch(amplifyAuthServiceProvider);
  return authService.getCurrentSession();
});

/// Provider for checking if user is signed in
final isSignedInProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(amplifyAuthServiceProvider);
  return authService.isSignedIn();
});

/// Provider for current user ID
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(amplifyAuthServiceProvider);
  return authService.getCurrentUserId();
});
