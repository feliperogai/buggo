import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Versão do app lida do pacote instalado.
///
/// Antes o número vivia escrito à mão em dois lugares — `pubspec.yaml` e a
/// tela de configurações — e nada garantia que continuassem iguais. Na
/// prática já tinham divergido: o pubspec dizia `1.0.0+3` enquanto a tela
/// mostrava `1.0.0`, e a coincidência só durou porque o nome da versão não
/// tinha mudado desde o começo.
///
/// Agora a única fonte é o `version:` do pubspec, que o build carimba no
/// pacote. Subir a versão para publicar passa a atualizar a tela sozinho.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});
