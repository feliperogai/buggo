/// Textos dos lembretes de estudo.
///
/// Fica separado do serviço de notificação de propósito: aqui não há plugin,
/// canal nem fuso horário — só texto e a regra de qual texto usar. Dá para
/// testar sem aparelho, e é o teste que garante que nenhum lembrete sai com
/// título vazio ou com o número de dias faltando.
library;

/// Em que situação a pessoa está quando o lembrete toca.
enum ReminderKind {
  /// O empurrãozinho do dia. Ninguém está devendo nada.
  daily,

  /// Tem sequência viva e o dia está acabando sem lição nenhuma. É o único
  /// lembrete que menciona perda — porque aqui existe perda de verdade.
  streakAtRisk,

  /// Faz dias que não aparece. O tom muda: acolher, não cobrar.
  comeback,
}

/// Um lembrete pronto para virar notificação.
class ReminderMessage {
  final String title;
  final String body;

  const ReminderMessage(this.title, this.body);

  @override
  String toString() => '$title — $body';
}

/// Escolhe o texto do lembrete.
///
/// A escolha é **determinística**, não sorteada: o mesmo dia sempre produz o
/// mesmo texto. Assim o teste consegue verificar o resultado, e a pessoa não
/// recebe a mesma frase duas vezes seguidas quando o app reagenda a semana
/// inteira de uma vez.
class ReminderMessages {
  ReminderMessages._();

  /// `{n}` é trocado pelo número de dias — de sequência ou de ausência,
  /// conforme o caso.
  static const _daily = <ReminderMessage>[
    ReminderMessage(
      'Erro 404: você hoje',
      'O Buggo procurou em todo lugar. Aparece aí e resolve esse bug.',
    ),
    ReminderMessage(
      'Cinco minutos contam',
      'Não precisa ser uma maratona. Uma lição curta e o dia fecha certo.',
    ),
    ReminderMessage(
      'Compilando sua rotina...',
      'Falta você. Uma lição rápida e a gente termina o build.',
    ),
    ReminderMessage(
      'Seu código não vai se escrever',
      'Ainda. Bora treinar um pouco?',
    ),
    ReminderMessage(
      'Tem desafio novo esperando',
      'Resolve num minuto e ainda leva moedas.',
    ),
    ReminderMessage(
      'Programar é hábito, não talento',
      'E hábito se constrói hoje. Uma lição já serve.',
    ),
    ReminderMessage(
      'O Buggo tá com saudade',
      'Bug nenhum se resolve sozinho. Vem cá.',
    ),
    ReminderMessage(
      'Um passo por dia',
      'Quem programa todo dia por 10 minutos passa quem programa 3h no domingo.',
    ),
    ReminderMessage(
      'Deu uma brecha aí?',
      'Fila do mercado, ônibus, intervalo. Uma lição cabe em qualquer uma.',
    ),
    ReminderMessage(
      'Nada de pressão',
      'Só um lembrete de que você começou algo. Continua?',
    ),
  ];

  static const _streakAtRisk = <ReminderMessage>[
    ReminderMessage(
      'Sua sequência de {n} dias tá por um fio',
      'Falta pouco pro dia virar. Uma lição salva ela.',
    ),
    ReminderMessage(
      '{n} dias seguidos. Vai perder agora?',
      'Ainda dá tempo. Uma lição rápida e a chama continua acesa.',
    ),
    ReminderMessage(
      'Não deixa quebrar hoje',
      'São {n} dias de esforço. Uma lição é tudo que falta.',
    ),
    ReminderMessage(
      'Faltam minutos pro dia acabar',
      'E {n} dias de sequência dependem dos próximos deles.',
    ),
  ];

  static const _comeback = <ReminderMessage>[
    ReminderMessage(
      'Faz {n} dias...',
      'Sem cobrança. O Buggo guardou seu lugar — volta quando puder.',
    ),
    ReminderMessage(
      'Seu progresso continua aí',
      'Nada foi perdido em {n} dias. É só voltar de onde parou.',
    ),
    ReminderMessage(
      'Recomeçar é permitido',
      'Ninguém aprende em linha reta. Uma lição curtinha hoje?',
    ),
    ReminderMessage(
      'Bora tirar a poeira do código?',
      'Você parou faz {n} dias. A primeira lição de volta é sempre a mais fácil.',
    ),
  ];

  static List<ReminderMessage> _poolFor(ReminderKind kind) => switch (kind) {
        ReminderKind.daily => _daily,
        ReminderKind.streakAtRisk => _streakAtRisk,
        ReminderKind.comeback => _comeback,
      };

  /// Quantos textos diferentes existem para [kind]. Serve para o serviço
  /// distribuir os dias sem repetir enquanto houver variedade.
  static int countFor(ReminderKind kind) => _poolFor(kind).length;

  /// O texto do lembrete.
  ///
  /// [index] é o dia que está sendo agendado (0 = hoje, 1 = amanhã...), e
  /// [days] é o número que aparece no texto: dias de sequência para
  /// [ReminderKind.streakAtRisk], dias sem estudar para
  /// [ReminderKind.comeback]. Ignorado no lembrete diário.
  static ReminderMessage pick(
    ReminderKind kind, {
    int index = 0,
    int days = 0,
  }) {
    final pool = _poolFor(kind);
    // O módulo mantém o índice dentro da lista mesmo quando o serviço agenda
    // mais dias do que existem textos: aí ele recomeça, e tudo bem.
    final message = pool[index.abs() % pool.length];
    if (!message.title.contains('{n}') && !message.body.contains('{n}')) {
      return message;
    }
    final n = days.toString();
    return ReminderMessage(
      message.title.replaceAll('{n}', n),
      message.body.replaceAll('{n}', n),
    );
  }
}
