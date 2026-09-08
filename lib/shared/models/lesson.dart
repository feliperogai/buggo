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

  // Code-fill IDE challenge fields
  // Template uses {0}, {1}, ... as placeholders
  final String? codeTemplate;
  final List<String>? availableTokens;
  final List<String>? correctTokens;
  final String? expectedOutput;

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
    this.codeTemplate,
    this.availableTokens,
    this.correctTokens,
    this.expectedOutput,
  });

  /// Monta a lição a partir do JSON do servidor — hoje só o desafio do dia
  /// chega por aí; as trilhas continuam sendo constantes de compilação.
  ///
  /// O gabarito não vem: o servidor confere a resposta e credita as moedas.
  /// Por isso `options` chega como lista de texto, sem `isCorrect`, e
  /// `correctTokens` fica nulo.
  factory Lesson.fromMap(Map<dynamic, dynamic> map) {
    final rawOptions = map['options'];
    final rawTokens = map['availableTokens'];

    return Lesson(
      id: map['id'] as String? ?? 'daily',
      title: map['title'] as String? ?? 'Desafio do dia',
      description: map['description'] as String? ?? '',
      type: map['type'] == 'codeChallenge'
          ? LessonType.codeChallenge
          : LessonType.quiz,
      question: map['question'] as String?,
      hint: map['hint'] as String?,
      options: rawOptions is List
          ? rawOptions
              .map((o) => LessonOption(text: '$o', isCorrect: false))
              .toList(growable: false)
          : const [],
      codeTemplate: map['codeTemplate'] as String?,
      availableTokens: rawTokens is List
          ? rawTokens.map((t) => '$t').toList(growable: false)
          : null,
      // Prêmio do desafio do dia é moeda, e quem credita é o servidor.
      xpReward: 0,
      coinReward: 0,
    );
  }
}

class CourseLevel {
  final int id;

  /// Linguagem a que este nível pertence (`logic`, `python`, `javascript`...).
  /// É o que separa as trilhas: cada linguagem tem a sua, e a trilha exibida
  /// é a da linguagem escolhida pelo usuário.
  final String languageId;

  final String title;
  final String description;
  final String emoji;
  final List<Lesson> lessons;
  final bool isLocked;

  const CourseLevel({
    required this.id,
    required this.languageId,
    required this.title,
    required this.description,
    required this.emoji,
    required this.lessons,
    this.isLocked = true,
  });
}
