import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/config/env_config.dart';
import '../../../core/net/server_diagnostics.dart';
import '../../../shared/models/user_profile.dart';
import '../../auth/data/auth_session.dart';

/// Falha ao confirmar a compra no backend, com mensagem pronta para a UI.
class PurchaseVerificationFailure implements Exception {
  final String message;
  PurchaseVerificationFailure(this.message);
  @override
  String toString() => message;
}

/// Manda o `purchaseToken` do Google Play para a API, que confirma a compra
/// com a Play Developer API antes de creditar. Nada é liberado só com a
/// palavra do app — ver `server/api/purchases/verify.ts`.
class PurchaseRepository {
  final _session = AuthSession();
  final http.Client _client;

  PurchaseRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<UserProfile> verify({
    required String productId,
    required String purchaseToken,
  }) async {
    final token = await _session.readToken();
    if (token == null) {
      throw PurchaseVerificationFailure(
        'Entre na sua conta para que a compra seja creditada.',
      );
    }

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('${EnvConfig.apiBaseUrl}/api/purchases/verify'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'productId': productId,
              'purchaseToken': purchaseToken,
            }),
          )
          .timeout(const Duration(seconds: 30));
    } on SocketException catch (e) {
      throw PurchaseVerificationFailure(
        'Sem conexão para confirmar a compra (${e.osError?.message ?? e.message}). '
        'Ela não foi perdida: abra a loja de novo quando tiver internet.',
      );
    } on TimeoutException {
      throw PurchaseVerificationFailure(
        'O servidor demorou para confirmar a compra. Abra a loja de novo em instantes.',
      );
    } on http.ClientException catch (e) {
      throw PurchaseVerificationFailure('Falha de rede ao confirmar a compra: ${e.message}');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw PurchaseVerificationFailure(
        ServerDiagnostics.describeNonJson(response) ??
            'Resposta inesperada do servidor (HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode >= 400) {
      throw PurchaseVerificationFailure(
        body['error'] as String? ?? 'Não foi possível confirmar a compra.',
      );
    }

    final profile = body['profile'];
    if (profile is! Map<String, dynamic>) {
      throw PurchaseVerificationFailure('O servidor não devolveu o perfil atualizado.');
    }
    return UserProfile.fromMap(profile);
  }
}
