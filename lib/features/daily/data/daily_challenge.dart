import '../../../shared/models/lesson.dart';

/// Desafio do dia, montado pelo servidor a partir da trilha e do ponto em que
/// a pessoa está.
///
/// O gabarito não vem junto: quem confere a resposta e credita as moedas é o
/// servidor. Ver `server/api/daily-challenge.ts`.
class DailyChallenge {
  final String id;
  final String date;
  final String languageId;
  final Lesson lesson;

  /// Quanto vale acertar, decidido por tabela no servidor.
  final int rewardCoins;

  /// Já resgatado hoje. O prêmio é um por dia.
  final bool alreadyClaimed;

  const DailyChallenge({
    required this.id,
    required this.date,
    required this.languageId,
    required this.lesson,
    required this.rewardCoins,
    required this.alreadyClaimed,
  });

  static DailyChallenge? fromMap(Map<String, dynamic> map) {
    final challenge = map['challenge'];
    if (challenge is! Map) return null;

    return DailyChallenge(
      id: map['challengeId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      languageId: map['languageId'] as String? ?? '',
      lesson: Lesson.fromMap(challenge),
      rewardCoins: map['rewardCoins'] as int? ?? 0,
      alreadyClaimed: map['alreadyClaimed'] as bool? ?? false,
    );
  }
}

/// Resposta do servidor depois de enviar a alternativa escolhida.
class DailyChallengeResult {
  final bool correct;
  final int coinsGranted;
  final bool alreadyClaimed;

  const DailyChallengeResult({
    required this.correct,
    required this.coinsGranted,
    required this.alreadyClaimed,
  });
}
