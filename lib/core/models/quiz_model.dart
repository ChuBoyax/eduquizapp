class QuizModel {
  final int id;
  final String title;
  final String? description;
  final String status;
  final int? timeLimit;
  final int? questionsCount;

  QuizModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.timeLimit,
    this.questionsCount,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      timeLimit: json['time_limit'],
      questionsCount: json['questions_count'],
    );
  }
}