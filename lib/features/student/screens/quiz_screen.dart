import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/api/room_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/question_model.dart';

class QuizScreen extends StatefulWidget {
  final String code;
  final int participantId;
  final String studentName;
  final bool isBattle;

  const QuizScreen({
    super.key,
    required this.code,
    required this.participantId,
    required this.studentName,
    this.isBattle = false,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with WidgetsBindingObserver {
  List<QuestionModel> _questions = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;

  // Anti-cheat: true habang nasa labas ng app ang student
  bool _isAway = false;

  // Stores answers: question_id -> answer data
  final Map<int, Map<String, dynamic>> _answers = {};
  final Map<int, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadQuestions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Huwag nang i-track pag tapos na mag-submit
    if (_hasSubmitted) return;

    // paused = mobile (minimize/lipat ng app), hidden = web (lipat ng tab
    // o minimize ng browser) at nauunang state din sa mobile bago mag-paused
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (!_isAway) {
        _isAway = true;
        RoomService().reportActivity(
          participantId: widget.participantId,
          event: 'left_app',
        );
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isAway) {
        _isAway = false;
        RoomService().reportActivity(
          participantId: widget.participantId,
          event: 'resumed',
        );
        Fluttertoast.showToast(
          msg: '⚠️ Leaving the app is recorded and visible to your teacher!',
          backgroundColor: AppColors.wrong,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }

  Future<void> _loadQuestions() async {
    final result = await RoomService().getQuestions(widget.code);
    if (result['success']) {
      setState(() {
        _questions = (result['data']['questions'] as List)
            .map((q) => QuestionModel.fromJson(q))
            .toList();
        _isLoading = false;
        // Init text controllers for fill in the blank / essay
        for (final q in _questions) {
          if (q.type == 'fill_in_the_blank' || q.type == 'essay') {
            _textControllers[q.id] = TextEditingController();
          }
        }
      });
    } else {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: 'Failed to load questions');
    }
  }

  void _selectOption(int questionId, int optionId) {
    setState(() {
      _answers[questionId] = {
        'question_id': questionId,
        'type': 'multiple_choice',
        'option_id': optionId,
      };
    });
  }

  void _selectTrueFalse(int questionId, int optionId) {
    setState(() {
      _answers[questionId] = {
        'question_id': questionId,
        'type': 'true_false',
        'option_id': optionId,
      };
    });
  }

  // Buuin ang answer payload ng isang tanong
  Map<String, dynamic> _buildAnswerPayload(QuestionModel question) {
    if (question.type == 'essay') {
      return {
        'question_id': question.id,
        'type': 'essay',
        'essay_answer': _textControllers[question.id]?.text ?? '',
      };
    } else if (question.type == 'fill_in_the_blank') {
      return {
        'question_id': question.id,
        'type': 'fill_in_the_blank',
        'text_answer': _textControllers[question.id]?.text ?? '',
      };
    }
    // Unanswered — blank na sagot
    return _answers[question.id] ??
        {
          'question_id': question.id,
          'type': question.type,
          'option_id': null,
        };
  }

  // ⚔️ Battle mode: i-lock ang sagot ngayon at agad ipadala —
  // real-time na-uupdate ang leaderboard sa teacher screen
  Future<void> _lockInAndNext() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final result = await RoomService().submitOneAnswer(
      participantId: widget.participantId,
      answer: _buildAnswerPayload(_questions[_currentIndex]),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success']) {
      setState(() => _currentIndex++);
    } else {
      Fluttertoast.showToast(msg: 'Failed to submit answer. Try again.');
    }
  }

  // ⚔️ Battle mode: huling tanong — i-lock ang sagot at tapusin ang quiz
  Future<void> _finishBattle() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final answerResult = await RoomService().submitOneAnswer(
      participantId: widget.participantId,
      answer: _buildAnswerPayload(_questions[_currentIndex]),
    );

    if (!answerResult['success']) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Fluttertoast.showToast(msg: 'Failed to submit answer. Try again.');
      return;
    }

    final result =
        await RoomService().finishQuiz(participantId: widget.participantId);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success']) {
      _hasSubmitted = true;
      final data = result['data'];
      context.go(
        '/student/result?score=${data['score']}&total=${data['total_points']}&code=${widget.code}',
      );
    } else {
      Fluttertoast.showToast(msg: 'Failed to finish. Please try again.');
    }
  }

  Future<void> _submitQuiz() async {
    // Build answers list
    final answersList =
        _questions.map(_buildAnswerPayload).toList();

    setState(() => _isSubmitting = true);

    final result = await RoomService().submitAnswers(
      participantId: widget.participantId,
      answers: answersList,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['success']) {
      _hasSubmitted = true;
      final data = result['data'];
      context.go(
        '/student/result?score=${data['score']}&total=${data['total_points']}&code=${widget.code}',
      );
    } else {
      Fluttertoast.showToast(msg: 'Failed to submit. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_questions.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('No questions found.',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;
    final isLast = _currentIndex == _questions.length - 1;

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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isBattle
                          ? '⚔️ Question ${_currentIndex + 1}/${_questions.length}'
                          : 'Question ${_currentIndex + 1}/${_questions.length}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${question.points} pt${question.points > 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.card,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 24),
                // Question card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    question.question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Answers
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildAnswerSection(question),
                  ),
                ),
                const SizedBox(height: 16),
                // Navigation buttons
                Row(
                  children: [
                    // Battle mode: bawal bumalik — locked na ang sagot
                    if (_currentIndex > 0 && !widget.isBattle)
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _currentIndex--),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text('← Previous',
                                style: TextStyle(color: Colors.white70)),
                          ),
                        ),
                      ),
                    if (_currentIndex > 0 && !widget.isBattle)
                      const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _isSubmitting
                            ? null
                            : isLast
                                ? (widget.isBattle
                                    ? _finishBattle
                                    : _submitQuiz)
                                : (widget.isBattle
                                    ? _lockInAndNext
                                    : () =>
                                        setState(() => _currentIndex++)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isLast
                                  ? [AppColors.correct, const Color(0xFF1DA57A)]
                                  : [AppColors.primary, AppColors.accent],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)
                              : Text(
                                  isLast
                                      ? '✓ Submit Quiz'
                                      : widget.isBattle
                                          ? '🔒 Lock In →'
                                          : 'Next →',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerSection(QuestionModel question) {
    switch (question.type) {
      case 'multiple_choice':
        return Column(
          children: question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _answers[question.id]?['option_id'] == option.id;
            final letter = String.fromCharCode(65 + index);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _selectOption(question.id, option.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(letter,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(option.optionText,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16)),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );

      case 'true_false':
        return Column(
          children: question.options.map((option) {
            final isSelected =
                _answers[question.id]?['option_id'] == option.id;
            final isTrue = option.optionText.toLowerCase() == 'true';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _selectTrueFalse(question.id, option.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isTrue
                            ? AppColors.correct.withValues(alpha: 0.2)
                            : AppColors.wrong.withValues(alpha: 0.2))
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? (isTrue ? AppColors.correct : AppColors.wrong)
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isTrue ? '✓ TRUE' : '✗ FALSE',
                        style: TextStyle(
                          color: isSelected
                              ? (isTrue ? AppColors.correct : AppColors.wrong)
                              : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );

      case 'fill_in_the_blank':
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _textControllers[question.id],
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: const InputDecoration(
              hintText: 'Type your answer here...',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(20),
            ),
          ),
        );

      case 'essay':
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _textControllers[question.id],
            maxLines: 8,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              hintText: 'Write your essay answer here...',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(20),
            ),
          ),
        );

      default:
        return const SizedBox();
    }
  }
}