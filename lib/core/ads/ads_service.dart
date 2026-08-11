import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/env_config.dart';

/// Anúncios premiados (rewarded) do AdMob.
///
/// O único anúncio do app: o usuário fica sem vidas, escolhe assistir, e
/// recebe as vidas de volta. É sempre opcional e sempre iniciado por ele —
/// anúncio premiado que roda sozinho viola a política do AdMob.
///
/// Nada aqui lança para a UI: se o SDK falhar, `showRewarded` devolve
/// `false` e a tela mostra a mensagem de erro normal.
class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  bool _initialized = false;
  RewardedAd? _ad;
  bool _loading = false;

  String get _adUnitId => EnvConfig.rewardedAdUnitId(isDebug: kDebugMode);

  /// Sobe o SDK e já deixa um anúncio engatilhado. Chamado uma vez no boot;
  /// falha silenciosamente porque anúncio nunca deve impedir o app de abrir.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      unawaitedPreload();
    } catch (e) {
      debugPrint('AdsService: falha ao inicializar o SDK: $e');
    }
  }

  /// Carrega o próximo anúncio em segundo plano. Um `RewardedAd` só pode ser
  /// exibido uma vez, então recarregamos depois de cada exibição para que o
  /// botão apareça pronto na próxima vez que as vidas acabarem.
  void unawaitedPreload() {
    if (!_initialized || _loading || _ad != null) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _loading = false;
          debugPrint('AdsService: anúncio não carregou: ${error.message}');
        },
      ),
    );
  }

  /// `true` quando há anúncio pronto para exibir agora.
  bool get isReady => _ad != null;

  /// Exibe o anúncio e resolve com `true` **somente** se o usuário assistiu
  /// o suficiente para ganhar a recompensa. Fechar no meio devolve `false`.
  Future<bool> showRewarded() async {
    final ad = _ad;
    if (ad == null) {
      unawaitedPreload();
      return false;
    }

    // Consome a instância antes de exibir: o SDK invalida o objeto ao
    // mostrá-lo, e deixá-lo em _ad permitiria um segundo show inválido.
    _ad = null;

    // `show()` resolve assim que o anúncio aparece, não quando termina. A
    // recompensa chega durante a exibição e o resultado só é conhecido no
    // fechamento, então quem decide o retorno é este Completer.
    final finished = Completer<bool>();
    var earned = false;

    void complete() {
      if (!finished.isCompleted) finished.complete(earned);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        complete();
        unawaitedPreload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        debugPrint('AdsService: falha ao exibir: ${error.message}');
        complete();
        unawaitedPreload();
      },
    );

    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    return finished.future;
  }
}
