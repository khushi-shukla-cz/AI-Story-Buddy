/// Centralized constants for the Peblo Smart Story Buddy app.
class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------
  // Story content
  // ---------------------------------------------------------------------
  static const String storyTitle = "Pip and the Whispering Woods";

  static const String storyText =
      "Once upon a time, a clever little robot named Pip lost his shiny "
      "blue gear in the Whispering Woods. Pip searched under mushrooms, "
      "behind sparkling streams, and even inside a curious owl's nest. "
      "With a little courage and a lot of curiosity, Pip finally found "
      "the gear shining brightly beside a friendly fox. Pip thanked the "
      "fox, fixed itself up, and skipped happily back home, ready for "
      "its next adventure!";

  // ---------------------------------------------------------------------
  // Mock backend quiz JSON (string form, parsed at runtime)
  // ---------------------------------------------------------------------
  static const String quizJson = '''
  {
    "questionId": "q_001",
    "question": "What colour was Pip the Robot's lost gear?",
    "options": ["Red", "Green", "Blue", "Yellow"],
    "answer": "Blue",
    "hint": "It was the same colour as the sky."
  }
  ''';

  // ---------------------------------------------------------------------
  // Lottie asset paths (Buddy states)
  // ---------------------------------------------------------------------
  static const String lottieIdle = 'assets/lottie/buddy_idle.json';
  static const String lottieReading = 'assets/lottie/buddy_reading.json';
  static const String lottieThinking = 'assets/lottie/buddy_thinking.json';
  static const String lottieEncouraging =
      'assets/lottie/buddy_encouraging.json';
  static const String lottieCelebrating =
      'assets/lottie/buddy_celebrating.json';

  // ---------------------------------------------------------------------
  // Adaptive hint engine messages
  // ---------------------------------------------------------------------
  static const String hintAttempt1 = "Let's try again!";
  static const String hintAttempt2 =
      "Think carefully. What colour was Pip's gear?";
  // Attempt 3+ reveals the hint from the quiz JSON itself.

  // ---------------------------------------------------------------------
  // Misc UI strings
  // ---------------------------------------------------------------------
  static const String ttsErrorMessage =
      "Oops! Pip couldn't start the story. Let's try again.";
  static const String successTitle = "Great Job!";
  static const String successSubtitle = "Pip found his blue gear!";

  // ---------------------------------------------------------------------
  // Storage keys
  // ---------------------------------------------------------------------
  static const String prefsKeyProgress = 'peblo_learner_progress';

  // ---------------------------------------------------------------------
  // Timings
  // ---------------------------------------------------------------------
  static const Duration shortAnim = Duration(milliseconds: 250);
  static const Duration mediumAnim = Duration(milliseconds: 450);
  static const Duration longAnim = Duration(milliseconds: 700);
}
