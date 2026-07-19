import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/api/room_service.dart';
import '../../../core/constants/app_colors.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _sectionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _joinRoom() async {
    if (_codeController.text.length != 6) {
      Fluttertoast.showToast(msg: 'Please enter a valid 6-digit room code');
      return;
    }
    if (_nameController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter your name');
      return;
    }

    setState(() => _isLoading = true);

    final result = await RoomService().joinRoom(
      code: _codeController.text,
      name: _nameController.text.trim(),
      studentId: _studentIdController.text.trim(),
      section: _sectionController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      final data = result['data'];
      final participantId = data['participant_id'];
      final code = data['room']['code'];
      final name = _nameController.text.trim();
      final status = data['room']['status'];
      final isBattle = data['room']['is_battle'] == true;

      if (status == 'ongoing') {
        context.go(
            '/student/quiz/$code?pid=$participantId&name=${Uri.encodeComponent(name)}&battle=${isBattle ? 1 : 0}');
      } else {
        Fluttertoast.showToast(
          msg: 'Joined! Waiting for teacher to start...',
          backgroundColor: AppColors.correct,
        );
        // Stay on waiting screen
        _showWaitingDialog(code, participantId, name, isBattle);
      }
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? 'Failed to join room',
        backgroundColor: AppColors.wrong,
      );
    }
  }

  void _showWaitingDialog(
      String code, int participantId, String name, bool isBattle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Waiting...',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Room Code: $code',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Waiting for teacher to start the quiz...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(
                  '/student/quiz/$code?pid=$participantId&name=${Uri.encodeComponent(name)}&battle=${isBattle ? 1 : 0}');
            },
            child: const Text('Quiz Started! Enter',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1440), Color(0xFF0B0817)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () => context.go('/role'),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back_ios,
                          color: Colors.white70, size: 18),
                      Text('Back',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                FadeInDown(
                  child: const Text(
                    '👨‍🎓 Join Quiz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the room code from your teacher',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 32),
                // Room Code Input (big and prominent)
                FadeInUp(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _codeController,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'ABC123',
                        hintStyle: TextStyle(
                          color: AppColors.border,
                          fontSize: 32,
                          letterSpacing: 8,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildTextField(
                    controller: _nameController,
                    label: 'Full Name *',
                    icon: Icons.person_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _buildTextField(
                    controller: _studentIdController,
                    label: 'Student ID (optional)',
                    icon: Icons.badge_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: _buildTextField(
                    controller: _sectionController,
                    label: 'Section (optional)',
                    icon: Icons.class_rounded,
                  ),
                ),
                const SizedBox(height: 30),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: GestureDetector(
                    onTap: _isLoading ? null : _joinRoom,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.correct, Color(0xFF1DA57A)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.correct.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : const Text(
                              'Join Room',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}