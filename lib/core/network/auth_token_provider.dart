abstract interface class AuthTokenProvider {
  Future<String?> readToken();
}
