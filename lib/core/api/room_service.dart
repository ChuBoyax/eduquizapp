import 'api_client.dart';

class RoomService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> joinRoom({
    required String code,
    required String name,
    String? studentId,
    String? section,
  }) async {
    try {
      final response = await _client.dio.post('/room/join', data: {
        'code': code.toUpperCase(),
        'name': name,
        'student_id': studentId,
        'section': section,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': 'Room not found or already finished.'};
    }
  }

  Future<Map<String, dynamic>> getQuestions(String code) async {
    try {
      final response = await _client.dio.get('/room/$code/questions');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load questions.'};
    }
  }

  Future<Map<String, dynamic>> submitAnswers({
    required int participantId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await _client.dio.post('/student/answer', data: {
        'participant_id': participantId,
        'answers': answers,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': 'Failed to submit answers.'};
    }
  }

  /// Anti-cheat: i-report kapag umalis o bumalik ang student sa app.
  /// event: 'left_app' | 'resumed'
  Future<void> reportActivity({
    required int participantId,
    required String event,
  }) async {
    try {
      await _client.dio.post('/participant/$participantId/activity', data: {
        'event': event,
      });
    } catch (_) {
      // Best-effort lang; huwag i-block ang quiz kapag nag-fail
    }
  }

  Future<Map<String, dynamic>> getLeaderboard(String code) async {
    try {
      final response = await _client.dio.get('/room/$code/leaderboard');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load leaderboard.'};
    }
  }

  Future<Map<String, dynamic>> createRoom(int quizId,
      {bool isBattle = false}) async {
    try {
      final response = await _client.dio.post('/room/create', data: {
        'quiz_id': quizId,
        'is_battle': isBattle,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': 'Failed to create room.'};
    }
  }

  /// Live Battle Mode: isang sagot lang — real-time na-uupdate ang leaderboard
  Future<Map<String, dynamic>> submitOneAnswer({
    required int participantId,
    required Map<String, dynamic> answer,
  }) async {
    try {
      final response = await _client.dio.post('/student/answer-one', data: {
        'participant_id': participantId,
        ...answer,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': 'Failed to submit answer.'};
    }
  }

  /// Live Battle Mode: tapusin ang quiz
  Future<Map<String, dynamic>> finishQuiz({
    required int participantId,
  }) async {
    try {
      final response = await _client.dio.post('/student/finish', data: {
        'participant_id': participantId,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': 'Failed to finish quiz.'};
    }
  }

  Future<Map<String, dynamic>> startRoom(String code) async {
    try {
      final response = await _client.dio.post('/room/$code/start');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': 'Failed to start quiz.'};
    }
  }

  Future<Map<String, dynamic>> endRoom(String code) async {
    try {
      final response = await _client.dio.post('/room/$code/end');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': 'Failed to end quiz.'};
    }
  }

  Future<Map<String, dynamic>> getTeacherQuizzes() async {
    try {
      final response = await _client.dio.get('/teacher/quizzes');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load quizzes.'};
    }
  }
}