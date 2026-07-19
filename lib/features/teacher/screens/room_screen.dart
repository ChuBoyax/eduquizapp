import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/api/realtime_client.dart';
import '../../../core/api/room_service.dart';
import '../../../core/constants/app_colors.dart';

class RoomScreen extends StatefulWidget {
  final String code;
  final bool isBattle;
  const RoomScreen({super.key, required this.code, this.isBattle = false});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  String _status = 'waiting';
  bool _isLoading = false;
  List<dynamic> _participants = [];
  Timer? _pollTimer;
  RoomRealtime? _realtime;
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    // Real-time leaderboard via WebSocket (Reverb) — instant updates
    _realtime = RoomRealtime(
      code: widget.code,
      onLeaderboardUpdated: (data) {
        if (!mounted) return;
        setState(() {
          _participants = (data['leaderboard'] as List?) ?? _participants;
        });
      },
      onConnectionChanged: (connected) {
        if (!mounted) return;
        setState(() => _isLive = connected);
      },
    );
    _realtime!.connect();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _realtime?.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshLeaderboard(),
    );
  }

  Future<void> _startQuiz() async {
    setState(() => _isLoading = true);
    final result = await RoomService().startRoom(widget.code);
    setState(() => _isLoading = false);

    if (result['success']) {
      setState(() => _status = 'ongoing');
      Fluttertoast.showToast(
        msg: 'Quiz started! Students can now answer.',
        backgroundColor: AppColors.correct,
      );
      _refreshLeaderboard();
      _startPolling();
    }
  }

  Future<void> _endQuiz() async {
    setState(() => _isLoading = true);
    final result = await RoomService().endRoom(widget.code);
    setState(() => _isLoading = false);

    if (result['success']) {
      _pollTimer?.cancel();
      setState(() => _status = 'finished');
      Fluttertoast.showToast(
        msg: 'Quiz ended!',
        backgroundColor: AppColors.correct,
      );
      _refreshLeaderboard();
    }
  }

  Future<void> _refreshLeaderboard() async {
    final result =
        await RoomService().getLeaderboard(widget.code);
    if (result['success'] && mounted) {
      setState(() {
        _participants = result['data']['leaderboard'];
      });
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.code));
    Fluttertoast.showToast(
      msg: 'Room code copied!',
      backgroundColor: AppColors.correct,
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/teacher/dashboard'),
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white70),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Room Manager',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (widget.isBattle)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.wrong.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.wrong),
                        ),
                        child: const Text(
                          '⚔️ BATTLE',
                          style: TextStyle(
                            color: AppColors.wrong,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Room Code Display
                FadeInDown(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 2),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Room Code',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _copyCode,
                              child: const Icon(Icons.copy_rounded,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // QR Code
                        QrImageView(
                          data: widget.code,
                          version: QrVersions.auto,
                          size: 150,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Students can scan this QR or enter the code',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status badge
                FadeInUp(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _status == 'waiting'
                          ? Colors.orange.withValues(alpha: 0.2)
                          : _status == 'ongoing'
                              ? AppColors.correct.withValues(alpha: 0.2)
                              : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _status == 'waiting'
                            ? Colors.orange
                            : _status == 'ongoing'
                                ? AppColors.correct
                                : AppColors.border,
                      ),
                    ),
                    child: Text(
                      _status == 'waiting'
                          ? '⏳ Waiting for students...'
                          : _status == 'ongoing'
                              ? '🟢 Quiz is ongoing'
                              : '🔴 Quiz ended',
                      style: TextStyle(
                        color: _status == 'waiting'
                            ? Colors.orange
                            : _status == 'ongoing'
                                ? AppColors.correct
                                : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons
                if (_status == 'waiting')
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: _isLoading ? null : _startQuiz,
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
                                '▶ Start Quiz',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),

                if (_status == 'ongoing') ...[
                  FadeInUp(
                    child: GestureDetector(
                      onTap: _refreshLeaderboard,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: const Text(
                          '🔄 Refresh Participants',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: _isLoading ? null : _endQuiz,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.wrong.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.wrong),
                        ),
                        child: const Text(
                          '⏹ End Quiz',
                          style: TextStyle(
                              color: AppColors.wrong,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],

                // Live participants
                if (_participants.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Live Results',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.correct.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '⚡ LIVE',
                            style: TextStyle(
                              color: AppColors.correct,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._participants.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final leftAppCount =
                        (item['left_app_count'] ?? 0) as int;
                    final isAway = item['app_state'] == 'left_app' &&
                        !(item['is_finished'] as bool);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAway
                              ? AppColors.wrong
                              : leftAppCount > 0
                                  ? Colors.orange
                                  : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '#${index + 1}',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: const TextStyle(
                                      color: Colors.white),
                                ),
                                if (isAway)
                                  const Text(
                                    '🔴 Currently out of the app!',
                                    style: TextStyle(
                                        color: AppColors.wrong,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  )
                                else if (leftAppCount > 0)
                                  Text(
                                    '⚠️ Left the app ${leftAppCount}x',
                                    style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${item['score']}/${item['total_points']}',
                            style: const TextStyle(
                                color: AppColors.correct,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            item['is_finished']
                                ? Icons.check_circle_rounded
                                : Icons.hourglass_empty_rounded,
                            color: item['is_finished']
                                ? AppColors.correct
                                : Colors.orange,
                            size: 18,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}