import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// De onde saiu o valor de [EnvConfig.apiBaseUrl]. Só para diagnóstico —
/// quando o app não fala com o servidor, a primeira pergunta é "essa build
/// tem URL?".
enum ApiBaseUrlSource {
  dartDefine('--dart-define'),
  dotenv('.env'),
  fallback('padrão embutido');

  const ApiBaseUrlSource(this.label);
  final String label;
}

/// Lê a configuração do app em três camadas, nesta ordem:
///
/// 1. `--dart-define=API_BASE_URL=...` — fixado na hora do build, é o que
///    CI/pipeline usa e o que vence quando existe.
/// 2. `.env` (veja `.env.example`) — o caminho normal na máquina de quem
///    desenvolve.
/// 3. [defaultApiBaseUrl] — a URL de produção, embutida no código.
///
/// A terceira camada existe porque o `.env` está fora do controle de versão:
/// qualquer build feita a partir de um clone limpo ficava sem `API_BASE_URL`
/// e o app caía calado no modo convidado, com login, sincronia de perfil e
/// ranking mortos. Não há segredo nenhum aqui — a URL da API é pública e já
/// viajava dentro de todo APK publicado.
class EnvConfig {
  EnvConfig._();

  /// API de produção (projeto `buggo-api` na Vercel).
  static const String defaultApiBaseUrl = 'https://buggo-api.vercel.app';

  static const String _definedApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _definedGoogleClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// Ler o `.env` deixou de ser obrigatório: se o arquivo não estiver na
  /// build, as outras duas camadas assumem em vez de a exceção derrubar o
  /// bootstrap inteiro.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('EnvConfig: .env não pôde ser lido ($e). '
          'Seguindo com --dart-define / padrão embutido.');
    }
  }

  /// Lê uma chave do `.env` sem exigir que ele tenha sido carregado.
  static String _fromDotenv(String key) {
    try {
      return dotenv.env[key]?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Base da API, ex: `https://buggo-api.vercel.app`. Sempre sem barra no
  /// final, para poder ser concatenada direto com `/api/...`.
  static String get apiBaseUrl => _normalizeBaseUrl(_rawApiBaseUrl.value);

  static ApiBaseUrlSource get apiBaseUrlSource => _rawApiBaseUrl.source;

  static ({String value, ApiBaseUrlSource source}) get _rawApiBaseUrl {
    if (_definedApiBaseUrl.trim().isNotEmpty) {
      return (value: _definedApiBaseUrl, source: ApiBaseUrlSource.dartDefine);
    }
    final fromFile = _fromDotenv('API_BASE_URL');
    if (fromFile.isNotEmpty) {
      return (value: fromFile, source: ApiBaseUrlSource.dotenv);
    }
    return (value: defaultApiBaseUrl, source: ApiBaseUrlSource.fallback);
  }

  /// Aceita o que estiver escrito no `.env` sem transformar erro de digitação
  /// em falha de rede: tira espaços e barras finais, e assume `https` quando
  /// o esquema não foi escrito (`buggo-api.vercel.app`). Sem isso a URL vira
  /// um caminho relativo e toda chamada falha.
  static String _normalizeBaseUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return '';
    if (!value.contains('://')) value = 'https://$value';
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  static bool get isApiConfigured => apiBaseUrl.isNotEmpty;

  /// Client ID OAuth **Web** do Google Cloud — a audiência que o backend
  /// exige no token (`GOOGLE_WEB_CLIENT_ID` lá). É o id web de propósito, não
  /// o Android: o app pede um token endereçado ao backend.
  static String get googleServerClientId {
    final defined = _definedGoogleClientId.trim();
    if (defined.isNotEmpty) return defined;
    return _fromDotenv('GOOGLE_SERVER_CLIENT_ID');
  }

  /// Bloco de anúncio recompensado do AdMob (vidas por anúncio). Vazio faz o
  /// app usar os IDs de teste do Google, que sempre preenchem e não faturam.
  static String get admobRewardedAdUnitId {
    const defined = String.fromEnvironment('ADMOB_REWARDED_AD_UNIT_ID');
    if (defined.trim().isNotEmpty) return defined.trim();
    return _fromDotenv('ADMOB_REWARDED_AD_UNIT_ID');
  }

  /// O login com Google só é oferecido quando a API e o client id existem —
  /// sem os dois o botão só poderia falhar ao ser tocado.
  static bool get isGoogleSignInConfigured =>
      isApiConfigured && googleServerClientId.isNotEmpty;
}
