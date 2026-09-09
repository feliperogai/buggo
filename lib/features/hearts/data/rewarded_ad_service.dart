import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/config/env_config.dart';

/// Anúncio recompensado que devolve todas as vidas.
///
/// O anúncio é **pré-carregado**: `RewardedAd.load` leva alguns segundos, e
/// carregar só no toque deixaria o usuário olhando para um botão travado. A
/// tela pede o carregamento ao abrir e o toque apenas exibe o que já está
/// pronto.
///
/// Um anúncio serve para uma exibição só. Depois de mostrado ele é descartado
/// e outro entra na fila, para o próximo dia já encontrar um pronto.
class RewardedAdService {
  RewardedAdService._();
  static final instance = RewardedAdService._();

  /// IDs oficiais de teste do Google. Funcionam sem conta AdMob e sempre
  /// preenchem — é o que roda enquanto `ADMOB_REWARDED_AD_UNIT_ID` não
  /// estiver no .env. Publicar com eles não gera receita nenhuma.
  static const _testAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testIos = 'ca-app-pub-3940256099942544/1712485313';

  static String get _adUnitId {
    if (usingTestAds) return Platform.isIOS ? _testIos : _testAndroid;
    return EnvConfig.admobRewardedAdUnitId;
  }

  /// Blocos de teste em vez dos reais.
  ///
  /// Em **debug é sempre teste**, mesmo com o bloco real no .env: exibir o
  /// anúncio de produção durante o desenvolvimento conta como tráfego
  /// inválido para o Google e pode suspender a conta AdMob. Em release, cai
  /// no teste só se o bloco não estiver configurado.
  static bool get usingTestAds =>
      kDebugMode || EnvConfig.admobRewardedAdUnitId.isEmpty;

  bool _initialized = false;
  RewardedAd? _ad;
  bool _loading = false;

  /// Há anúncio pronto para exibir agora?
  bool get isReady => _ad != null;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  /// Carrega um anúncio em segundo plano. Chamar várias vezes é seguro: sai
  /// cedo se já houver um pronto ou um carregamento em andamento.
  Future<void> preload() async {
    if (_ad != null || _loading) return;
    _loading = true;
    try {
      await _ensureInitialized();
      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _loading = false;
          },
          onAdFailedToLoad: (error) {
            debugPrint('Anúncio recompensado não carregou: ${error.message}');
            _ad = null;
            _loading = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('Falha ao iniciar o SDK de anúncios: $e');
      _loading = false;
    }
  }

  /// Exibe o anúncio. [onEarned] roda **uma vez**, e só quando o Google
  /// confirma que a pessoa assistiu até o ponto que dá direito à recompensa —
  /// fechar antes do fim não chama nada.
  ///
  /// Devolve false quando não havia anúncio pronto, para a tela avisar em vez
  /// de parecer que o toque não funcionou.
  Future<bool> show({required VoidCallback onEarned}) async {
    final ad = _ad;
    if (ad == null) {
      unawaited(preload());
      return false;
    }
    _ad = null; // um anúncio, uma exibição

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(preload()); // já deixa o próximo pronto
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Anúncio falhou ao exibir: ${error.message}');
        ad.dispose();
        unawaited(preload());
      },
    );

    await ad.show(onUserEarnedReward: (_, __) => onEarned());
    return true;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
