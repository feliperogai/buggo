import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/env_config.dart';
import '../../../core/net/server_diagnostics.dart';
import '../../../shared/models/user_profile.dart';
import '../../auth/data/auth_session.dart';
import 'daily_challenge.dart';

/// Falha ao falar com o servidor sobre o desafio do dia, com mensagem pronta
/// para a tela.
class DailyChallengeFailure implements Exception {
  final String message;
  DailyChallengeFailure(this.message);
  @override
  String toString() => message;
}

/// Conversa com `/api/daily-challenge`.
///
/// O desafio é gerado por IA no servidor, a partir da linguagem e do ponto em
/// que a pessoa está — nada disso é enviado daqui, o servidor já sabe. A
/// resposta também é conferida lá: o app não recebe o gabarito.
class DailyChallengeRepository {
  final _session = AuthSession();
  final http.Client _client;

  DailyChallengeRepository({http.Client? client})
      : _client = client ?? http.Client();

  Uri get _uri => Uri.parse('${EnvConfig.apiBaseUrl}/api/daily-challenge');

  /// Busca o desafio de hoje. Devolve `null` quando não há um — visitante sem
  /// conta, servidor sem as chaves de IA configuradas, ou geração que falhou.
  /// Em todos esses casos a tela simplesmente não mostra o cartão.
  Future<DailyChallenge?> fetchToday() async {
    final token = await _session.readToken();
    if (token == null) return null;

    final http.Response response;
    try {
      response = await _client
          .get(_uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      return null;
    } on TimeoutException {
      return null;
    } on http.ClientException {
      return null;
    }

    if (response.statusCode != 200) return null;

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return DailyChallenge.fromMap(body);
    } catch (_) {
      return null;
    }
  }

  /// Manda a resposta — a alternativa escolhida, ou o código escrito. Quem
  /// confere e credita as moedas é o servidor; no caso do código, é a IA
  /// revisora lendo o que a pessoa escreveu.
  ///
  /// Devolve o resultado e o perfil atualizado, quando houve crédito.
  Future<(DailyChallengeResult, UserProfile?)> submit({
    required String challengeId,
    int? optionIndex,
    String? code,
  }) async {
    assert(
      (optionIndex == null) != (code == null),
      'mande a alternativa OU o código, nunca os dois',
    );

    final token = await _session.readToken();
    if (token == null) {
      throw DailyChallengeFailure('Entre na sua conta para valer o desafio.');
    }

    final http.Response response;
    try {
      response = await _client
          .post(
            _uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'challengeId': challengeId,
              'answer': code != null
                  ? {'code': code}
                  : {'optionIndex': optionIndex},
            }),
          )
          // Corrigir código passa por uma chamada de IA, então a espera é
          // maior que a de responder múltipla escolha.
          .timeout(const Duration(seconds: 45));
    } on SocketException catch (e) {
      throw DailyChallengeFailure(
        'Sem conexão para enviar a resposta (${e.osError?.message ?? e.message}).',
      );
    } on TimeoutException {
      throw DailyChallengeFailure('O servidor demorou para responder.');
    } on http.ClientException catch (e) {
      throw DailyChallengeFailure('Falha de rede: ${e.message}');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw DailyChallengeFailure(
        ServerDiagnostics.describeNonJson(response) ??
            'Resposta inesperada do servidor (HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode >= 400) {
      throw DailyChallengeFailure(
        body['error'] as String? ?? 'Não foi possível enviar a resposta.',
      );
    }

    final profile = body['profile'];
    return (
      DailyChallengeResult(
        correct: body['correct'] as bool? ?? false,
        coinsGranted: body['coinsGranted'] as int? ?? 0,
        alreadyClaimed: body['alreadyClaimed'] as bool? ?? false,
        feedback: body['feedback'] as String?,
      ),
      profile is Map<String, dynamic> ? UserProfile.fromMap(profile) : null,
    );
  }
}
