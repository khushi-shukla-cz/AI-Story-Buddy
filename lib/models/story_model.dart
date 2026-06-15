/// Data model representing the story content shown to the learner.
class StoryModel {
  final String title;
  final String text;

  const StoryModel({
    required this.title,
    required this.text,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      title: json['title'] as String? ?? 'Story Time',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'text': text,
      };
}
