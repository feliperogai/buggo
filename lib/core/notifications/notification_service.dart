import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'reminder_schedule.dart';

/// Lembretes de estudo, agendados no próprio aparelho.
///
/// Não há Firebase, servidor de push nem custo: o Android guarda os alarmes e
/// entrega as notificações mesmo com o app fechado. O preço disso é que o
/// texto é decidido na hora de agendar, não na hora de tocar — por isso o
/// plano é refeito toda vez que o app abre e toda vez que uma lição é
/// concluída (ver [sync]).
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Só Android está publicado. No desktop dos testes o plugin nem existe, e
  /// tentar inicializá-lo derruba o bootstrap.
  bool get _supported => !kIsWeb && Platform.isAndroid;

  static const _channelId = 'buggo_lembretes';
  static const _channelName = 'Lembretes de estudo';
  static const _channelDescription =
      'Avisos para manter a sequência e não perder o desafio do dia.';

  /// O ícone monocromático em `res/drawable`; o colorido do app viraria um
  /// quadrado branco sem forma na barra de status.
  static const _icon = '@drawable/ic_notification';

  Future<void> init() async {
    if (!_supported || _ready) return;

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
      ),
    );

    // O canal é criado na inicialização e não a cada notificação: a partir do
    // Android 8 é ele que decide som e prioridade, e o usuário pode ajustar
    // isso nas configurações do sistema.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.defaultImportance,
        ));

    _ready = true;
  }

  /// Pede a permissão de notificação (Android 13+).
  ///
  /// Devolve `false` quando a pessoa recusa — e isso não é erro: o app segue
  /// funcionando igual, só sem lembrete.
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    await init();
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Apaga o que estava agendado e reagenda a partir do estado atual.
  ///
  /// Chamado na abertura do app, ao mudar a preferência e ao concluir uma
  /// lição. É o cancelamento que impede o lembrete de "não perca a sequência"
  /// de chegar cinco minutos depois de a pessoa ter estudado.
  Future<void> sync({
    required bool enabled,
    required int hour,
    required int streak,
    DateTime? lastStudyDate,
    DateTime? now,
  }) async {
    if (!_supported) return;
    await init();

    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('lembretes: não foi possível limpar os agendamentos: $e');
      return;
    }

    if (!enabled) return;

    final plan = ReminderSchedule.build(
      now: now ?? DateTime.now(),
      enabled: enabled,
      hour: hour,
      streak: streak,
      lastStudyDate: lastStudyDate,
    );

    for (final reminder in plan) {
      try {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.message.title,
          body: reminder.message.body,
          // O horário do plano é local. Converter para UTC preserva o
          // instante, então o alarme toca na hora certa do relógio da pessoa
          // sem o app precisar carregar o banco de fusos inteiro.
          scheduledDate: tz.TZDateTime.from(reminder.when, tz.UTC),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              icon: _icon,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
          ),
          // Inexato de propósito: o Android entrega dentro de uma janela e
          // não gasta a permissão de alarme exato, que exige justificativa na
          // revisão do Google Play. Lembrete de estudo não precisa de
          // precisão de segundo.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e) {
        // Um lembrete que falha não pode derrubar os outros seis.
        debugPrint('lembretes: falha ao agendar ${reminder.id}: $e');
      }
    }

    debugPrint('lembretes: ${plan.length} agendado(s)');
  }

  /// Cancela tudo. Usado quando a pessoa desliga os lembretes.
  Future<void> cancelAll() async {
    if (!_supported) return;
    await init();
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('lembretes: falha ao cancelar: $e');
    }
  }
}
