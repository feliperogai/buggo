/// Ids dos produtos criados no Google Play Console. Têm que bater
/// exatamente com `server/lib/products.ts` — o servidor recusa qualquer id
/// que não esteja no catálogo dele.
///
/// Os preços NÃO ficam aqui: o Play devolve o valor já localizado e na moeda
/// do usuário, e é esse que a tela mostra.
class StoreProducts {
  StoreProducts._();

  static const coins200 = 'coins_200';
  static const coins450 = 'coins_450';
  static const coins950 = 'coins_950';

  /// Assinatura mensal do Buggo+ (vidas ilimitadas enquanto ativa).
  static const buggoPlusMonthly = 'buggo_plus_monthly';

  static const consumables = <String>{coins200, coins450, coins950};
  static const subscriptions = <String>{buggoPlusMonthly};
  static const all = <String>{...consumables, ...subscriptions};

  /// Quantas moedas cada pacote entrega. Só serve para o texto da tela — quem
  /// credita de verdade é o servidor, depois de confirmar com o Google.
  static const coinAmounts = <String, int>{
    coins200: 200,
    coins450: 450,
    coins950: 950,
  };
}
