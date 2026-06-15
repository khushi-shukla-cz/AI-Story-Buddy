/// Data model representing a single quiz question, parsed dynamically
/// from a (mock) backend JSON response. The UI must be built entirely
/// from this model — no hardcoded options.
class QuizModel {
  final String questionId;
  final String question;
  final List<String> options;
  final String answer;
  final String hint;

  const QuizModel({
    required this.questionId,
    required this.question,
    required this.options,
    required this.answer,
    required this.hint,
  });

  /// Creates a [QuizModel] from a JSON map. Throws a [FormatException]
  /// with a friendly message if required fields are missing or malformed,
  /// so callers can show graceful error UI instead of crashing.
  factory QuizModel.fromJson(Map<String, dynamic> json) {
    try {
      final question = json['question'] as String?;
      final optionsRaw = json['options'] as List<dynamic>?;
      final answer = json['answer'] as String?;
      final hint = json['hint'] as String?;
      final questionId = json['questionId'] as String? ?? 'unknown';

      if (question == null || question.trim().isEmpty) {
        throw const FormatException('Missing "question" field.');
      }
      if (optionsRaw == null || optionsRaw.isEmpty) {
        throw const FormatException('Missing or empty "options" field.');
      }
      if (answer == null || answer.trim().isEmpty) {
        throw const FormatException('Missing "answer" field.');
      }

      final options = optionsRaw.map((e) => e.toString()).toList();

      if (!options.contains(answer)) {
        throw const FormatException(
          '"answer" must be one of the provided "options".',
        );
      }

      return QuizModel(
        questionId: questionId,
        question: question,
        options: options,
        answer: answer,
        hint: hint ?? "Take a guess — you can do it!",
      );
    } catch (e) {
      // Re-throw as a FormatException with a friendly, consistent message
      // so the UI layer can present a single error type.
      throw FormatException('Invalid quiz data: ${e.toString()}');
    }
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'question': question,
        'options': options,
        'answer': answer,
        'hint': hint,
      };
}
