/// API Configuration for RapidPhoto Mobile App
class ApiConfig {
  /// Backend API base URL
  ///
  /// For local development with backend running on localhost:
  /// - Android emulator: 'http://10.0.2.2:8080'
  /// - iOS simulator: 'http://localhost:8080'
  /// - Physical device: Use your local IP address
  ///
  /// For production: Use the deployed backend URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://rapid-photo-dev-alb-351686176.us-east-1.elb.amazonaws.com',
  );

  /// API version prefix
  static const String apiVersion = '/api/v1';

  /// Full API base URL with version
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  /// Connection timeout in milliseconds
  static const int connectTimeout = 30000;

  /// Receive timeout in milliseconds
  static const int receiveTimeout = 30000;
}
