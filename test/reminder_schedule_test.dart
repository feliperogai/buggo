import 'package:flutter_test/flutter_test.dart';
import 'package:buggo/core/notifications/reminder_messages.dart';
import 'package:buggo/core/notifications/reminder_schedule.dart';

/// O que este teste protege é o lado chato de notificação: cobrar quem já
/// estudou, avisar sobre uma sequência que não existe, empilhar dois avisos
/// no mesmo dia ou mandar texto com `{n}` cru na tela de alguém.
///
/// Nada aqui depende do plugin nem de aparelho — [ReminderSchedule] é função
/// pura de (agora, perfil, preferência).
void main() {
  // Uma quinta-feira qualquer, 10h da manhã.
  final manha = DateTime(2026, 3, 12, 10);

  group('lembretes', () {
    test('desligado não agenda nada', () {
      final plan = ReminderSchedule.build(
        now: manha,
        enabled: false,
        hour: 19,
        streak: 5,
        lastStudyDate: manha.subtract(const Duration(days: 1)),
      );

      expect(plan, isEmpty);
    });

    test('quem já estudou hoje não recebe cobrança hoje', () {
      final plan = ReminderSchedule.build(
        now: manha,
        enabled: true,
        hour: 19,
        streak: 4,
        lastStudyDate: DateTime(2026, 3, 12, 9),
      );

      final hoje = plan.where((r) => r.when.day == 12);
      expect(hoje, isEmpty,
          reason: 'estudou às 9h e ainda assim receberia lembrete');
      // Os próximos dias continuam agendados.
      expect(plan, isNotEmpty);
    });

    test('sequência viva e dia em aberto gera o aviso das 21h', () {
      final plan = ReminderSchedule.build(
        now: manha,
        enabled: true,
        hour: 19,
        streak: 7,
        lastStudyDate: DateTime(2026, 3, 11, 20),
      );

      final risco =
          plan.where((r) => r.kind == ReminderKind.streakAtRisk).toList();
      expect(risco.length, 1);
      expect(risco.first.when, DateTime(2026, 3, 12, 21));
      // O número de dias pode cair no título ou no corpo, conforme o texto
      // sorteado pela data.
      final texto = risco.first.message.toString();
      expect(texto, contains('7'));
    });

    test('sem sequência não existe aviso de sequência', () {
      final plan = ReminderSchedule.build(
        now: manha,
        enabled: true,
        hour: 19,
        streak: 0,
        lastStudyDate: null,
      );

      expect(plan.any((r) => r.kind == ReminderKind.streakAtRisk), isFalse);
    });

    test('o dia com aviso de sequência não leva também o lembrete comum', () {
      final plan = ReminderSchedule.build(
        now: manha,
        enabled: true,
        hour: 19,
        streak: 3,
        lastStudyDate: DateTime(2026, 3, 11, 20),
      );

      final hoje = plan.where((r) => r.when.day == 12).toList();
      expect(hoje.length, 1, reason: 'dois lembretes no mesmo dia');
      expect(hoje.first.kind, ReminderKind.streakAtRisk);
    });

    test('não agenda no passado', () {
      // 20h, com lembrete marcado para as 19h: hoje já passou.
      final noite = DateTime(2026, 3, 12, 20);
      final plan = ReminderSchedule.build(
        now: noite,
        enabled: true,
        hour: 19,
        streak: 0,
      );

      expect(plan.every((r) => r.when.isAfter(noite)), isTrue);
    });

    test('sumiu por dias, o tom muda para volta', () {
      final plan = ReminderSchedule.build(
        now: manha,
        enabled: true,
        hour: 19,
        streak: 0,
        lastStudyDate: manha.subtract(const Duration(days: 5)),
      );

      expect(plan, isNotEmpty);
      expect(plan.every((r) => r.kind == ReminderKind.comeback), isTrue);
    });

    test('um dia sem estudar ainda é rotina, não abandono', () {
      final plan = ReminderSchedule.build(
        now: manha,
        enabled: true,
        hour: 19,
        streak: 0,
        lastStudyDate: manha.subtract(const Duration(days: 1)),
      );

      expect(plan.every((r) => r.kind == ReminderKind.daily), isTrue);
    });

    test('cobre a semana, um lembrete por dia, sem id repetido', () {
      final plan = ReminderSchedule.build(
        now: manha,
        enabled: true,
        hour: 19,
        streak: 0,
      );

      expect(plan.length, ReminderSchedule.horizonDays);
      expect(plan.map((r) => r.id).toSet().length, plan.length);
      expect(plan.map((r) => r.when.day).toSet().length, plan.length);
      expect(plan.every((r) => r.when.hour == 19), isTrue);
    });

    test('respeita a hora escolhida', () {
      final plan = ReminderSchedule.build(
        now: manha,
        enabled: true,
        hour: 8,
        streak: 0,
      );

      // 8h de hoje já passou (são 10h), então o primeiro é o de amanhã.
      expect(plan.first.when, DateTime(2026, 3, 13, 8));
    });

    test('nenhum texto vaza a marcação {n}', () {
      for (final streak in [0, 1, 9]) {
        for (final ausencia in [0, 1, 5, 30]) {
          final plan = ReminderSchedule.build(
            now: manha,
            enabled: true,
            hour: 19,
            streak: streak,
            lastStudyDate: manha.subtract(Duration(days: ausencia)),
          );
          for (final r in plan) {
            expect(r.message.title, isNot(contains('{n}')));
            expect(r.message.body, isNot(contains('{n}')));
            expect(r.message.title.trim(), isNotEmpty);
            expect(r.message.body.trim(), isNotEmpty);
          }
        }
      }
    });

    test('o texto gira entre os dias em vez de repetir', () {
      final plan = ReminderSchedule.build(
        now: manha,
        enabled: true,
        hour: 19,
        streak: 0,
      );

      final titulos = plan.map((r) => r.message.title).toSet();
      expect(titulos.length, plan.length,
          reason: 'a semana inteira com o mesmo título');
    });

    test('o mesmo dia produz sempre o mesmo plano', () {
      List<String> textos(DateTime now) => ReminderSchedule.build(
            now: now,
            enabled: true,
            hour: 19,
            streak: 2,
            lastStudyDate: DateTime(2026, 3, 11),
          ).map((r) => r.message.toString()).toList();

      expect(textos(manha), textos(DateTime(2026, 3, 12, 11)));
    });
  });

  group('mensagens', () {
    test('todo tipo tem mais de um texto', () {
      for (final kind in ReminderKind.values) {
        expect(ReminderMessages.countFor(kind), greaterThan(1), reason: '$kind');
      }
    });

    test('índice fora da lista não estoura', () {
      final m = ReminderMessages.pick(ReminderKind.daily, index: 9999);
      expect(m.title.trim(), isNotEmpty);
    });

    test('o aviso de sequência sempre mostra o número de dias', () {
      for (var i = 0;
          i < ReminderMessages.countFor(ReminderKind.streakAtRisk);
          i++) {
        final m =
            ReminderMessages.pick(ReminderKind.streakAtRisk, index: i, days: 12);
        expect('${m.title} ${m.body}', contains('12'));
      }
    });
  });
}
