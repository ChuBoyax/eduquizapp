import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/auth/screens/teacher_login_screen.dart';
import 'features/student/screens/join_room_screen.dart';
import 'features/student/screens/quiz_screen.dart';
import 'features/student/screens/result_screen.dart';
import 'features/student/screens/leaderboard_screen.dart';
import 'features/teacher/screens/teacher_dashboard_screen.dart';
import 'features/teacher/screens/room_screen.dart';

void main() {
  runApp(const EduQuizApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/role', builder: (_, __) => const RoleSelectionScreen()),
    GoRoute(path: '/teacher/login', builder: (_, __) => const TeacherLoginScreen()),
    GoRoute(path: '/teacher/dashboard', builder: (_, __) => const TeacherDashboardScreen()),
    GoRoute(
      path: '/teacher/room/:code',
      builder: (_, state) => RoomScreen(
        code: state.pathParameters['code']!,
        isBattle: state.uri.queryParameters['battle'] == '1',
      ),
    ),
    GoRoute(path: '/student/join', builder: (_, __) => const JoinRoomScreen()),
    GoRoute(
      path: '/student/quiz/:code',
      builder: (_, state) => QuizScreen(
        code: state.pathParameters['code']!,
        participantId: int.parse(state.uri.queryParameters['pid'] ?? '0'),
        studentName: state.uri.queryParameters['name'] ?? '',
        isBattle: state.uri.queryParameters['battle'] == '1',
      ),
    ),
    GoRoute(
      path: '/student/result',
      builder: (_, state) => ResultScreen(
        score: int.parse(state.uri.queryParameters['score'] ?? '0'),
        total: int.parse(state.uri.queryParameters['total'] ?? '0'),
        code: state.uri.queryParameters['code'] ?? '',
      ),
    ),
    GoRoute(
      path: '/leaderboard/:code',
      builder: (_, state) => LeaderboardScreen(
        code: state.pathParameters['code']!,
      ),
    ),
  ],
);

class EduQuizApp extends StatelessWidget {
  const EduQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EduQuiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        fontFamily: 'sans-serif',
      ),
      routerConfig: _router,
    );
  }
}