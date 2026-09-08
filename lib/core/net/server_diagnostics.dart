import 'package:http/http.dart' as http;

/// Traduz uma resposta que não é JSON no motivo real, em vez de deixar todas
/// virarem "Resposta inesperada do servidor".
///
/// Existe por causa de um caso concreto: a API na Vercel estava com a
/// *Deployment Protection* ligada, então todo pedido vindo de um aparelho era
/// respondido com a página de login da Vercel — HTML, HTTP 401 — antes mesmo
/// de chegar na função. Do lado do app isso aparecia como "resposta
/// inesperada" e nada indicava que o problema era uma chave num painel.
class ServerDiagnostics {
  ServerDiagnostics._();

  /// Devolve uma mensagem para o usuário quando [response] veio em HTML (ou
  /// qualquer coisa que não seja JSON), ou `null` quando o corpo parece JSON
  /// de verdade e a falha é outra.
  static String? describeNonJson(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    final body = response.body.trimLeft();
    final looksLikeHtml =
        contentType.contains('text/html') || body.startsWith('<');
    if (!looksLikeHtml) return null;

    if (_isVercelAuthWall(response, body)) {
      return 'O servidor devolveu a tela de login da Vercel em vez da API '
          '(HTTP ${response.statusCode}). Desligue a Deployment Protection do '
          'projeto buggo-api em Settings > Deployment Protection: enquanto ela '
          'estiver ligada, nenhum aparelho consegue falar com o servidor.';
    }

    return 'O servidor devolveu uma página HTML em vez de JSON '
        '(HTTP ${response.statusCode}). Confira se a URL da API está certa e '
        'se o deploy está no ar.';
  }

  /// O muro de autenticação da Vercel responde 401 com HTML e cita o próprio
  /// fluxo de SSO no corpo. Os dois sinais juntos evitam confundir com uma
  /// página de erro qualquer do provedor.
  static bool _isVercelAuthWall(http.Response response, String body) {
    if (response.statusCode != 401 && response.statusCode != 403) return false;
    return body.contains('_vercel/sso') ||
        body.contains('vercel.com/sso-api') ||
        body.contains('Authentication Required');
  }
}
