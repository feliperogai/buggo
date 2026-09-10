import 'reminder_messages.dart';

/// Um lembrete já decidido: quando toca e o que diz.
class PlannedReminder {
  /// Id estável no plugin. Não se repete dentro de um mesmo plano.
  final int id;

  /// Horário local em que a notificação deve aparecer.
  final DateTime when;

  final ReminderKind kind;
  final ReminderMessage message;

  const PlannedReminder({
    required this.id,
    required this.when,
    required this.kind,
    required this.message,
  });
}

/// Decide quais lembretes agendar, sem tocar em plugin nenhum.
///
/// Está separado do [NotificationService] porque é aqui que mora a única
/// parte que pode errar de um jeito chato: mandar "sua sequência vai acabar"
/// para quem já estudou hoje, ou empilhar dois lembretes no mesmo minuto.
/// Sendo função pura de (agora, perfil, preferência), dá para testar cada
/// caso desses sem aparelho.
///
/// **Limite honesto:** notificação local não sabe o que aconteceu depois de
/// ser agendada. Por isso o app refaz o plano a cada abertura e a cada lição
/// concluída — é o que cancela o lembrete de hoje de quem acabou de estudar.
class ReminderSchedule {
  ReminderSchedule._();

  /// Quantos dias à frente o plano cobre. Sete é o suficiente para quem some
  /// por uma semana continuar recebendo, e curto o bastante para o plano ser
  /// refeito com dados atuais assim que a pessoa voltar.
  static const int horizonDays = 7;

  /// Hora do lembrete de sequência em risco. Tarde o bastante para a pessoa
  /// já ter tido o dia inteiro, cedo o bastante para ainda dar tempo.
  static const int streakAlertHour = 21;

  /// Depois de tantos dias parada, o tom muda de "bora treinar" para
  /// "volta quando puder".
  static const int comebackAfterDays = 3;

  static const int _streakId = 100;
  static const int _dailyIdBase = 200;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Monta o plano de lembretes.
  ///
  /// [hour] é a hora escolhida pela pessoa nas configurações. [streak] e
  /// [lastStudyDate] vêm do perfil.
  static List<PlannedReminder> build({
    required DateTime now,
    required bool enabled,
    required int hour,
    required int streak,
    DateTime? lastStudyDate,
  }) {
    if (!enabled) return const [];

    final studiedToday =
        lastStudyDate != null && _sameDay(lastStudyDate, now);
    final daysAway = lastStudyDate == null
        ? 0
        : _dateOnly(now).difference(_dateOnly(lastStudyDate)).inDays;

    final kind = daysAway >= comebackAfterDays
        ? ReminderKind.comeback
        : ReminderKind.daily;

    // O dia do ano faz o texto girar sem sorteio: dois aparelhos no mesmo dia
    // recebem a mesma frase, e o teste consegue prever qual é.
    final seed = _dateOnly(now).difference(DateTime(now.year)).inDays;

    final plan = <PlannedReminder>[];

    // Sequência viva, dia ainda não fechado e nenhuma lição feita: é o
    // lembrete mais urgente do dia, e o único que fala em perder algo.
    final streakAtRisk =
        streak > 0 && !studiedToday && now.hour < streakAlertHour;
    if (streakAtRisk) {
      plan.add(PlannedReminder(
        id: _streakId,
        when: DateTime(now.year, now.month, now.day, streakAlertHour),
        kind: ReminderKind.streakAtRisk,
        message: ReminderMessages.pick(
          ReminderKind.streakAtRisk,
          index: seed,
          days: streak,
        ),
      ));
    }

    for (var day = 0; day < horizonDays; day++) {
      final date = _dateOnly(now).add(Duration(days: day));
      final when = DateTime(date.year, date.month, date.day, hour);

      if (day == 0) {
        // Já estudou hoje: não existe nada a lembrar.
        if (studiedToday) continue;
        // A hora já passou. Agendar no passado não dispara nada.
        if (!when.isAfter(now)) continue;
        // Com a sequência em risco, o aviso das 21h já cobre hoje. Dois
        // lembretes no mesmo dia seria justamente o que faz desinstalar.
        if (streakAtRisk) continue;
      }

      plan.add(PlannedReminder(
        id: _dailyIdBase + day,
        when: when,
        kind: kind,
        message: ReminderMessages.pick(
          kind,
          index: seed + day,
          days: daysAway + day,
        ),
      ));
    }

    return plan;
  }
}
