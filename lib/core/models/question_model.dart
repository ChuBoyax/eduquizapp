class QuestionModel {
  final int id;
  final String question;
  final String type;
  final int points;
  final List<OptionModel> options;

  QuestionModel({
    required this.id,
    required this.question,
    required this.type,
    required this.points,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'],
      question: json['question'],
      type: json['type'],
      points: json['points'],
      options: (json['options'] as List? ?? [])
          .map((o) => OptionModel.fromJson(o))
          .toList(),
    );
  }
}

class OptionModel {
  final int id;
  final String optionText;

  OptionModel({required this.id, required this.optionText});

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      id: json['id'],
      optionText: json['option_text'],
    );
  }
}