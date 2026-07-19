import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/api/room_service.dart';
import '../../../core/constants/app_colors.dart';

class LeaderboardScreen extends StatefulWidget {
  final String code;
  const LeaderboardScreen({super.key, required this.code});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final result = await RoomService().getLeaderboard(widget.code);
    if (result['success']) {
      setState(() {
        _leaderboard = result['data']['leaderboard'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/role'),
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white70),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '🏆 Leaderboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _loadLeaderboard,
                      child: const Icon(Icons.refresh_rounded,
                          color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Room Code: ${widget.code}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _leaderboard.length,
                      itemBuilder: (context, index) {
                        final item = _leaderboard[index];
                        final rank = item['rank'];
                        final isTop3 = rank <= 3;

                        String rankEmoji;
                        Color rankColor;
                        switch (rank) {
                          case 1:
                            rankEmoji = '🥇';
                            rankColor = const Color(0xFFFFD700);
                            break;
                          case 2:
                            rankEmoji = '🥈';
                            rankColor = const Color(0xFFC0C0C0);
                            break;
                          case 3:
                            rankEmoji = '🥉';
                            rankColor = const Color(0xFFCD7F32);
                            break;
                          default:
                            rankEmoji = '#$rank';
                            rankColor = AppColors.textSecondary;
                        }

                        return FadeInUp(
                          delay: Duration(milliseconds: index * 100),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isTop3
                                  ? rankColor.withValues(alpha: 0.1)
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isTop3
                                    ? rankColor.withValues(alpha: 0.4)
                                    : AppColors.border,
                                width: isTop3 ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    rankEmoji,
                                    style: TextStyle(
                                      fontSize: isTop3 ? 24 : 16,
                                      color: rankColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isTop3 ? 17 : 15,
                                          fontWeight: isTop3
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        '${item['percentage']}%',
                                        style: TextStyle(
                                            color: rankColor, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${item['score']}',
                                      style: TextStyle(
                                        color: rankColor,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '/${item['total_points']} pts',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}