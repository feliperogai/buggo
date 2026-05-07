enum LessonType { explanation, quiz, codeChallenge, dragDrop, fillBlank }

class LessonOption {
  final String text;
  final bool isCorrect;

  const LessonOption({required this.text, required this.isCorrect});
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final LessonType type;
  final String? explanation;
  final String? codeSnippet;
  final String? question;
  final List<LessonOption> options;
  final String? correctAnswer;
  final String? hint;
  final int xpReward;
  final int coinReward;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.explanation,
    this.codeSnippet,
    this.question,
    this.options = const [],
    this.correctAnswer,
    this.hint,
    this.xpReward = 10,
    this.coinReward = 5,
  });
}

class CourseLevel {
  final int id;
  final String title;
  final String description;
  final String emoji;
  final List<Lesson> lessons;
  final bool isLocked;

  const CourseLevel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.lessons,
    this.isLocked = true,
  });
}
