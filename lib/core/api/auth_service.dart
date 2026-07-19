import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> teacherLogin(
      String email, String password) async {
    try {
      final response = await _client.dio.post('/teacher/login', data: {
        'email': email,
        'password': password,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', response.data['token']);
      await prefs.setString('user_name', response.data['user']['name']);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': 'Invalid email or password.'};
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('/teacher/logout');
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }
}