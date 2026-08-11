import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/env_config.dart';
import '../../auth/data/auth_session.dart';
import 'daily_challenge_models.dart';

/// Erro com mensagem já pronta para mostrar ao aluno.
class DailyChallengeException implements Exception {
  final String message;

  /// true quando o aluno esgotou as tentativas do dia — a tela usa isso para
  /// desabilitar o botão em vez de só mostrar o erro.
  final bool outOfAttempts;

  DailyChallengeException(this.message, {this.outOfAttempts = false});

  @override
  String toString() => message;
}

/// Fala com `/api/challenge/*`.
///
/// O app nunca chama a DeepSeek direto: a chave da API vive só no backend
/// (ver `server/lib/deepseek.ts`). Um APK é aberto em minutos, e chave
/// vazada vira cobrança na conta.
class DailyChallengeRepository {
  final _session = AuthSession();

  bool get isConfigured => EnvConfig.isApiConfigured;

  Uri _uri(String path) => Uri.parse('${EnvConfig.apiBaseUrl}$path');

  Future<Map<String, String>> _headers() async {
    final token = await _session.readToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Busca o desafio de hoje, gerando um novo se ainda não existir.
  ///
  /// [topics] são os títulos das lições que o aluno já concluiu — o currículo
  /// mora no app, então é ele quem manda esse contexto para o prompt.
  Future<DailyChallenge> fetchToday({required List<String> topics}) async {
    final response = await http.post(
      _uri('/api/challenge/daily'),
      headers: await _headers(),
      body: jsonEncode({'topics': topics}),
    );
    final body = _decode(response);
    return DailyChallenge.fromMap(body['challenge'] as Map<String, dynamic>);
  }

  /// Envia o código para correção pela IA.
  Future<ChallengeGrade> submit(String code) async {
    final response = await http.post(
      _uri('/api/challenge/submit'),
      headers: await _headers(),
      body: jsonEncode({'code': code}),
    );
    final body = _decode(response);
    return ChallengeGrade.fromMap(body);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw DailyChallengeException('O servidor respondeu de forma inesperada.');
    }
    if (response.statusCode >= 400) {
      throw DailyChallengeException(
        body['error'] as String? ?? 'Não foi possível completar a operação.',
        outOfAttempts: response.statusCode == 429,
      );
    }
    return body;
  }
}
