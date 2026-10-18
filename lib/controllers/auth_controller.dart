import '../api.dart';
import '../models/auth_session.dart';

class AuthController {
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await Api.req(
      'POST',
      '/login',
      auth: false,
      body: {'email': email, 'password': password},
    );
    final session = AuthSession.fromJson(response);
    if (session.role != 'staff') {
      throw Exception('This mobile app is for staff accounts only.');
    }

    await Api.saveToken(session.token);
    return session;
  }
}
