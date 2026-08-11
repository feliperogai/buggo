/// Desafio do dia, como o backend devolve.
///
/// O gabarito (`expectedBehavior`) fica só no servidor e por isso não existe
/// aqui — ver `server/api/challenge/daily.ts`.
class DailyChallenge {
  final String id;
  final String language;
  final String title;
  final String statement;
  final String starterCode;
  final int xpReward;
  final int coinReward;
  final bool solved;
  final int attempts;
  final int attemptsLeft;
  final String? lastFeedback;

  const DailyChallenge({
    required this.id,
    required this.language,
    required this.title,
    required this.statement,
    required this.starterCode,
    required this.xpReward,
    required this.coinReward,
    required this.solved,
    required this.attempts,
    required this.attemptsLeft,
    this.lastFeedback,
  });

  factory DailyChallenge.fromMap(Map<String, dynamic> map) => DailyChallenge(
        id: map['id'] as String,
        language: map['language'] as String? ?? 'python',
        title: map['title'] as String? ?? 'Desafio do dia',
        statement: map['statement'] as String? ?? '',
        starterCode: map['starterCode'] as String? ?? '',
        xpReward: (map['xpReward'] as num?)?.toInt() ?? 0,
        coinReward: (map['coinReward'] as num?)?.toInt() ?? 0,
        solved: map['solved'] as bool? ?? false,
        attempts: (map['attempts'] as num?)?.toInt() ?? 0,
        attemptsLeft: (map['attemptsLeft'] as num?)?.toInt() ?? 0,
        lastFeedback: map['lastFeedback'] as String?,
      );
}

/// Resultado da correção feita pela IA.
class ChallengeGrade {
  final bool passed;
  final String feedback;

  /// Linha apontada pela IA como origem do problema, quando ela consegue
  /// identificar. 1-indexada, para casar com a numeração do editor.
  final int? errorLine;

  final int attemptsLeft;
  final int xpEarned;
  final int coinsEarned;

  /// Perfil já atualizado pelo servidor quando o aluno acerta. Nulo quando
  /// erra, porque nada mudou.
  final Map<String, dynamic>? profile;

  const ChallengeGrade({
    required this.passed,
    required this.feedback,
    required this.errorLine,
    required this.attemptsLeft,
    required this.xpEarned,
    required this.coinsEarned,
    this.profile,
  });

  factory ChallengeGrade.fromMap(Map<String, dynamic> map) => ChallengeGrade(
        passed: map['passed'] as bool? ?? false,
        feedback: map['feedback'] as String? ?? '',
        errorLine: (map['errorLine'] as num?)?.toInt(),
        attemptsLeft: (map['attemptsLeft'] as num?)?.toInt() ?? 0,
        xpEarned: (map['xpEarned'] as num?)?.toInt() ?? 0,
        coinsEarned: (map['coinsEarned'] as num?)?.toInt() ?? 0,
        profile: map['profile'] as Map<String, dynamic>?,
      );
}
