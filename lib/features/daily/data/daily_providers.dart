import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/user_provider.dart';
import 'daily_challenge.dart';
import 'daily_challenge_repository.dart';

final dailyChallengeRepositoryProvider = Provider<DailyChallengeRepository>(
  (ref) => DailyChallengeRepository(),
);

/// Desafio de hoje, ou `null` quando não há um para mostrar.
///
/// Depende de [userProvider] de propósito: trocar de linguagem ou concluir
/// uma lição muda o desafio que o servidor monta, então a busca refaz.
final dailyChallengeProvider = FutureProvider<DailyChallenge?>((ref) async {
  final user = ref.watch(userProvider);
  // Convidado não tem conta, e sem conta não há onde creditar moeda.
  if (user == null || user.isGuest) return null;

  return ref.read(dailyChallengeRepositoryProvider).fetchToday();
});
