/// Аппын алдааны төрлүүд
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class FirestoreException extends AppException {
  const FirestoreException(super.message);
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class ConfigException extends AppException {
  const ConfigException(super.message);
}
