import '../../shared/models/lesson.dart';

const int logicFoundationLevelCount = 2;

const List<CourseLevel> pythonCurriculum = [
  CourseLevel(
    id: 0,
    title: 'Fundamentos: jogos de lógica',
    description: 'Enigmas, sequências e escolhas antes das linguagens',
    emoji: 'LOG',
    isLocked: false,
    lessons: [
      Lesson(
        id: 'logic1_0',
        title: 'Missão: detetive da lógica',
        description: 'Observe pistas e encontre regras',
        type: LessonType.explanation,
        explanation:
            'Lógica é perceber como as coisas se conectam.\n\nEm um enigma, você olha as pistas, separa o que importa, descobre a regra e escolhe a melhor resposta. Aqui a trilha começa como um jogo de raciocínio: observar, comparar, testar ideias e decidir com calma.',
        xpReward: 12,
        coinReward: 6,
      ),
      Lesson(
        id: 'logic1_1',
        title: 'Labirinto das setas',
        description: 'Escolha o caminho que vence a fase',
        type: LessonType.quiz,
        question:
            'Você está em um labirinto. O caminho A bate em uma parede, o B volta para o início e o C chega na chave. Qual caminho você escolhe?',
        options: [
          LessonOption(text: 'Caminho C', isCorrect: true),
          LessonOption(text: 'Caminho A', isCorrect: false),
          LessonOption(text: 'Caminho B', isCorrect: false),
        ],
        hint: 'Use as pistas: parede e volta ao início não resolvem a fase.',
        xpReward: 14,
        coinReward: 7,
      ),
      Lesson(
        id: 'logic1_2',
        title: 'Sequência das gemas',
        description: 'Descubra o padrão escondido',
        type: LessonType.quiz,
        question:
            'A sequência é: azul, verde, verde, azul, verde, verde... Qual gema vem agora?',
        options: [
          LessonOption(text: 'Azul', isCorrect: true),
          LessonOption(text: 'Verde', isCorrect: false),
          LessonOption(text: 'Vermelha', isCorrect: false),
        ],
        hint: 'O padrão repete um azul e dois verdes.',
        xpReward: 16,
        coinReward: 8,
      ),
      Lesson(
        id: 'logic1_3',
        title: 'Duelo de pontuação',
        description: 'Compare valores sem se confundir',
        type: LessonType.quiz,
        question:
            'No duelo, Lia fez 17 pontos e Rafa fez 21. Quem venceu a rodada?',
        options: [
          LessonOption(text: 'Rafa, porque 21 é maior que 17', isCorrect: true),
          LessonOption(text: 'Lia, porque 17 veio primeiro', isCorrect: false),
          LessonOption(
              text: 'Empate, porque os dois pontuaram', isCorrect: false),
        ],
        hint: 'Compare os números, não a ordem em que eles apareceram.',
        xpReward: 16,
        coinReward: 8,
      ),
      Lesson(
        id: 'logic1_4',
        title: 'Regra secreta do castelo',
        description: 'Entenda regras antes de agir',
        type: LessonType.explanation,
        explanation:
            'Muitos jogos funcionam com regras simples: a porta abre com a chave certa, a ponte cai com peso demais, o baú só abre depois da pista final.\n\nPensar com lógica é sempre perguntar: qual é a regra? O que eu já sei? O que ainda falta descobrir?',
        xpReward: 14,
        coinReward: 7,
      ),
      Lesson(
        id: 'logic1_5',
        title: 'Guardião das duas chaves',
        description: 'Use uma regra com duas pistas',
        type: LessonType.quiz,
        question:
            'O guardião deixa passar somente quem tem a chave dourada e a lanterna acesa. Quem passa?',
        options: [
          LessonOption(
              text: 'Mila: chave dourada e lanterna acesa', isCorrect: true),
          LessonOption(
              text: 'Nico: chave dourada e lanterna apagada', isCorrect: false),
          LessonOption(
              text: 'Teca: chave prateada e lanterna acesa', isCorrect: false),
        ],
        hint: 'As duas condições precisam ser verdadeiras ao mesmo tempo.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'logic1_6',
        title: 'Baús mentirosos',
        description: 'Use pistas para eliminar opções',
        type: LessonType.quiz,
        question:
            'Há dois baús. Um deles tem a estrela. O baú vermelho diz: "a estrela está no azul". O baú azul diz: "o vermelho está mentindo". Se apenas uma frase é verdadeira, onde está a estrela?',
        options: [
          LessonOption(text: 'No baú vermelho', isCorrect: true),
          LessonOption(text: 'No baú azul', isCorrect: false),
          LessonOption(text: 'Nos dois baús', isCorrect: false),
        ],
        hint: 'Se estivesse no azul, as duas frases seriam verdadeiras.',
        xpReward: 20,
        coinReward: 10,
      ),
      Lesson(
        id: 'logic1_7',
        title: 'Mapa da fase',
        description: 'Organize a ordem das ações',
        type: LessonType.quiz,
        question:
            'Para vencer a fase, você precisa acender a tocha, atravessar a ponte escura e abrir o portão. Qual ordem faz sentido?',
        options: [
          LessonOption(
              text: 'Acender a tocha -> atravessar a ponte -> abrir o portão',
              isCorrect: true),
          LessonOption(
              text: 'Abrir o portão -> atravessar a ponte -> acender a tocha',
              isCorrect: false),
          LessonOption(
              text: 'Atravessar no escuro -> abrir o portão -> acender a tocha',
              isCorrect: false),
        ],
        hint: 'A ponte escura precisa da tocha antes.',
        xpReward: 18,
        coinReward: 9,
      ),
    ],
  ),
  CourseLevel(
    id: 1,
    title: 'Fundamentos: enigmas e estratégia',
    description: 'Memória, dedução, prioridades e desafios em camadas',
    emoji: 'REP',
    isLocked: true,
    lessons: [
      Lesson(
        id: 'logic2_0',
        title: 'Sala dos padrões',
        description: 'Encontre repetições no tabuleiro',
        type: LessonType.explanation,
        explanation:
            'Padrões aparecem em sequências, mapas, senhas, cartas e movimentos.\n\nQuando você percebe que algo se repete, fica mais fácil prever o próximo passo e tomar uma decisão melhor.',
        xpReward: 14,
        coinReward: 7,
      ),
      Lesson(
        id: 'logic2_1',
        title: 'Senha colorida',
        description: 'Complete uma sequência visual',
        type: LessonType.quiz,
        question:
            'A senha do portal é: vermelho, azul, amarelo, vermelho, azul... Qual cor falta?',
        options: [
          LessonOption(text: 'Amarelo', isCorrect: true),
          LessonOption(text: 'Vermelho', isCorrect: false),
          LessonOption(text: 'Azul', isCorrect: false),
        ],
        hint: 'A sequência repete sempre as três cores na mesma ordem.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'logic2_2',
        title: 'Torre dos pesos',
        description: 'Compare pistas em cadeia',
        type: LessonType.quiz,
        question:
            'A pedra A pesa mais que a B. A pedra B pesa mais que a C. Qual é a mais pesada?',
        options: [
          LessonOption(text: 'Pedra A', isCorrect: true),
          LessonOption(text: 'Pedra B', isCorrect: false),
          LessonOption(text: 'Pedra C', isCorrect: false),
        ],
        hint: 'Se A é maior que B, e B é maior que C, A fica no topo.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'logic2_3',
        title: 'Ilha das escolhas',
        description: 'Escolha o caminho mais seguro',
        type: LessonType.quiz,
        question:
            'Você precisa chegar ao farol. O barco rápido está furado, a ponte curta está quebrada e a trilha longa está livre. Qual escolha é melhor?',
        options: [
          LessonOption(text: 'Usar a trilha longa', isCorrect: true),
          LessonOption(text: 'Pegar o barco furado', isCorrect: false),
          LessonOption(text: 'Ir pela ponte quebrada', isCorrect: false),
        ],
        hint: 'A melhor opção nem sempre é a mais curta.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'logic2_4',
        title: 'Elimine impossíveis',
        description: 'Resolva por dedução',
        type: LessonType.explanation,
        explanation:
            'Dedução é tirar opções que não combinam com as pistas.\n\nQuando sobram poucas possibilidades, a resposta aparece com mais clareza. Em jogos de lógica, isso é mais forte do que tentar adivinhar.',
        xpReward: 16,
        coinReward: 8,
      ),
      Lesson(
        id: 'logic2_5',
        title: 'Quem está no meio?',
        description: 'Monte a ordem pela pista',
        type: LessonType.quiz,
        question:
            'Lia está à esquerda de Noah. Noah está à esquerda de Maya. Quem está no meio?',
        options: [
          LessonOption(text: 'Noah', isCorrect: true),
          LessonOption(text: 'Lia', isCorrect: false),
          LessonOption(text: 'Maya', isCorrect: false),
        ],
        hint: 'A ordem fica Lia, Noah, Maya.',
        xpReward: 20,
        coinReward: 10,
      ),
      Lesson(
        id: 'logic2_6',
        title: 'Memória das cartas',
        description: 'Guarde pistas importantes',
        type: LessonType.quiz,
        question:
            'Você viu estas cartas por 3 segundos: estrela, lua, chave. Qual item estava no meio?',
        options: [
          LessonOption(text: 'Lua', isCorrect: true),
          LessonOption(text: 'Estrela', isCorrect: false),
          LessonOption(text: 'Chave', isCorrect: false),
        ],
        hint: 'A ordem era estrela, lua, chave.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'logic2_7',
        title: 'Desafio final: portal das linguagens',
        description: 'Resolva o último enigma para liberar novas trilhas',
        type: LessonType.quiz,
        question:
            'No painel final aparece a sequência: 2, 4, 8, 16, ?. Qual número abre o portal?',
        options: [
          LessonOption(text: '32', isCorrect: true),
          LessonOption(text: '20', isCorrect: false),
          LessonOption(text: '24', isCorrect: false),
        ],
        hint:
            'Cada número dobra o anterior. Ao concluir este enigma, as linguagens ficam liberadas.',
        xpReward: 40,
        coinReward: 20,
      ),
    ],
  ),
  CourseLevel(
    id: 2,
    title: 'Python Essencial',
    description: 'Sintaxe, variáveis, textos e cálculos',
    emoji: 'PY',
    isLocked: true,
    lessons: [
      Lesson(
        id: 'py_basic_0',
        title: 'O Python fala com print',
        description: 'Mostre informações na tela',
        type: LessonType.explanation,
        explanation:
            'print() é uma função pronta do Python. Ela mostra valores na tela e ajuda você a entender o que o programa está fazendo.',
        codeSnippet: 'print("Olá, Python!")',
        xpReward: 12,
        coinReward: 6,
      ),
      Lesson(
        id: 'py_basic_1',
        title: 'Use print()',
        description: 'Complete o primeiro comando',
        type: LessonType.codeChallenge,
        question: 'Complete para mostrar "Buggo aprende Python":',
        codeTemplate: '{0}("Buggo aprende Python")',
        availableTokens: ['print', 'input', 'show', 'display'],
        correctTokens: ['print'],
        expectedOutput: 'Buggo aprende Python',
        hint: 'print() mostra texto na tela.',
        xpReward: 24,
        coinReward: 12,
      ),
      Lesson(
        id: 'py_basic_2',
        title: 'Variáveis no código',
        description: 'Nomeie informações importantes',
        type: LessonType.explanation,
        explanation:
            'Variáveis deixam o código mais claro. Em vez de repetir valores soltos, você guarda cada valor com um nome.',
        codeSnippet: 'nome = "Felipe"\npontos = 10\nprint(nome, pontos)',
        xpReward: 14,
        coinReward: 7,
      ),
      Lesson(
        id: 'py_basic_3',
        title: 'Crie e use uma variável',
        description: 'Guarde uma linguagem e mostre',
        type: LessonType.codeChallenge,
        question: 'Complete para mostrar "Python":',
        codeTemplate: '{0} = "Python"\nprint({1})',
        availableTokens: ['linguagem', 'Python', '"Python"', 'nome'],
        correctTokens: ['linguagem', 'linguagem'],
        expectedOutput: 'Python',
        hint: 'Use o mesmo nome da variável nas duas linhas.',
        xpReward: 26,
        coinReward: 13,
      ),
      Lesson(
        id: 'py_basic_4',
        title: 'Números e operadores',
        description: 'Some, subtraia, multiplique e divida',
        type: LessonType.explanation,
        explanation:
            'Python calcula expressões numéricas com operadores: + soma, - subtrai, * multiplica, / divide e % pega o resto.',
        codeSnippet:
            'preco = 20\nquantidade = 3\ntotal = preco * quantidade\nprint(total)',
        xpReward: 14,
        coinReward: 7,
      ),
      Lesson(
        id: 'py_basic_5',
        title: 'Calcule um total',
        description: 'Use multiplicação',
        type: LessonType.codeChallenge,
        question: 'Complete para mostrar 60:',
        codeTemplate:
            'preco = 20\nquantidade = 3\ntotal = preco {0} quantidade\nprint({1})',
        availableTokens: ['*', '+', 'total', 'preco', 'quantidade'],
        correctTokens: ['*', 'total'],
        expectedOutput: '60',
        hint: 'Total de compra costuma ser preço vezes quantidade.',
        xpReward: 30,
        coinReward: 15,
      ),
      Lesson(
        id: 'py_basic_6',
        title: 'Textos também somam',
        description: 'Junte palavras com +',
        type: LessonType.codeChallenge,
        question: 'Complete para mostrar "Olá Ana":',
        codeTemplate: 'nome = "Ana"\nmensagem = "Olá " {0} nome\nprint({1})',
        availableTokens: ['+', '-', 'mensagem', 'nome'],
        correctTokens: ['+', 'mensagem'],
        expectedOutput: 'Olá Ana',
        hint: 'Com textos, + junta as partes.',
        xpReward: 30,
        coinReward: 15,
      ),
      Lesson(
        id: 'py_basic_7',
        title: 'Leia o erro antes de tentar de novo',
        description: 'Erro também ensina',
        type: LessonType.quiz,
        question: 'Se você escreveu prnit("oi"), qual é o problema?',
        options: [
          LessonOption(
              text: 'O nome da função print está escrito errado',
              isCorrect: true),
          LessonOption(text: 'Python não aceita texto', isCorrect: false),
          LessonOption(text: 'Todo programa precisa de loop', isCorrect: false),
        ],
        hint: 'Pequenos erros de nome são muito comuns.',
        xpReward: 18,
        coinReward: 9,
      ),
    ],
  ),
  CourseLevel(
    id: 3,
    title: 'Funções em Python',
    description: 'Crie comandos reutilizáveis e claros',
    emoji: 'DEF',
    isLocked: true,
    lessons: [
      Lesson(
        id: 'func_0',
        title: 'Por que criar funções?',
        description: 'Evite repetição e organize ideias',
        type: LessonType.explanation,
        explanation:
            'Uma função é um bloco de código com nome. Você cria uma vez e chama sempre que precisar.\n\nFunções deixam o programa mais organizado porque cada parte passa a ter uma responsabilidade clara.',
        codeSnippet:
            'def avisar():\n    print("Processo concluído")\n\navisar()',
        xpReward: 16,
        coinReward: 8,
      ),
      Lesson(
        id: 'func_1',
        title: 'Crie uma função simples',
        description: 'Defina e chame um bloco',
        type: LessonType.codeChallenge,
        question: 'Complete para mostrar "Bem-vindo":',
        codeTemplate: '{0} boas_vindas():\n    print("Bem-vindo")\n\n{1}()',
        availableTokens: ['def', 'boas_vindas', 'print', 'func'],
        correctTokens: ['def', 'boas_vindas'],
        expectedOutput: 'Bem-vindo',
        hint: 'def cria a função; depois você chama pelo nome.',
        xpReward: 34,
        coinReward: 17,
      ),
      Lesson(
        id: 'func_2',
        title: 'Parâmetros',
        description: 'Envie informações para a função',
        type: LessonType.explanation,
        explanation:
            'Parâmetros são variáveis que a função recebe.\n\nAssim a mesma função consegue trabalhar com valores diferentes sem duplicar código.',
        codeSnippet:
            'def saudar(nome):\n    print("Olá", nome)\n\nsaudar("Lia")\nsaudar("Rafa")',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'func_3',
        title: 'Função com parâmetro',
        description: 'Use o valor recebido',
        type: LessonType.codeChallenge,
        question: 'Complete para mostrar "Olá Ana":',
        codeTemplate:
            'def saudar({0}):\n    print("Olá", {1})\n\nsaudar("Ana")',
        availableTokens: ['nome', 'idade', 'print', '"Ana"'],
        correctTokens: ['nome', 'nome'],
        expectedOutput: 'Olá Ana',
        hint:
            'O parâmetro nome recebe o valor "Ana" quando a função é chamada.',
        xpReward: 36,
        coinReward: 18,
      ),
      Lesson(
        id: 'func_4',
        title: 'Mais de um parâmetro',
        description: 'Combine valores dentro da função',
        type: LessonType.explanation,
        explanation:
            'Funções podem receber vários parâmetros. Isso ajuda quando a regra precisa de mais de uma informação, como preço e quantidade.',
        codeSnippet:
            'def mostrar_total(preco, quantidade):\n    total = preco * quantidade\n    print("Total", total)\n\nmostrar_total(10, 3)',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'func_5',
        title: 'Cálculo dentro da função',
        description: 'Use parâmetros para calcular',
        type: LessonType.codeChallenge,
        question: 'Complete para mostrar "Total 30":',
        codeTemplate:
            'def mostrar_total(preco, quantidade):\n    total = preco {0} quantidade\n    print("Total", {1})\n\nmostrar_total(10, 3)',
        availableTokens: ['*', '+', 'total', 'preco', 'quantidade'],
        correctTokens: ['*', 'total'],
        expectedOutput: 'Total 30',
        hint: 'Multiplique preço por quantidade e mostre total.',
        xpReward: 40,
        coinReward: 20,
      ),
      Lesson(
        id: 'func_6',
        title: 'Função com decisão',
        description: 'A função também pode escolher caminhos',
        type: LessonType.explanation,
        explanation:
            'Uma função pode conter if, else, loops e outros comandos. Isso permite criar uma regra com nome e reutilizar essa regra em vários lugares.',
        codeSnippet:
            'def verificar(nota):\n    if nota >= 7:\n        print("Aprovado")\n    else:\n        print("Revisar")\n\nverificar(8)',
        xpReward: 20,
        coinReward: 10,
      ),
      Lesson(
        id: 'func_7',
        title: 'Valide uma nota',
        description: 'Use if dentro da função',
        type: LessonType.codeChallenge,
        question: 'Complete para mostrar "Aprovado":',
        codeTemplate:
            'def verificar(nota):\n    if nota {0} 7:\n        print("Aprovado")\n    else:\n        print("Revisar")\n\nverificar(8)',
        availableTokens: ['>=', '<', '==', 'else', 'nota'],
        correctTokens: ['>='],
        expectedOutput: 'Aprovado',
        hint: 'Nota 8 deve passar na regra nota >= 7.',
        xpReward: 42,
        coinReward: 21,
      ),
      Lesson(
        id: 'func_8',
        title: 'Reutilização real',
        description: 'Chame a mesma função mais de uma vez',
        type: LessonType.codeChallenge,
        question: 'Complete para mostrar 6 e 10:',
        codeTemplate:
            'def dobrar(numero):\n    print(numero {0} 2)\n\ndobrar(3)\ndobrar({1})',
        availableTokens: ['*', '+', '5', '3'],
        correctTokens: ['*', '5'],
        expectedOutput: '6\n10',
        hint: 'A mesma função deve funcionar com números diferentes.',
        xpReward: 44,
        coinReward: 22,
      ),
      Lesson(
        id: 'func_9',
        title: 'Funções pequenas vencem',
        description: 'Clareza acima de código gigante',
        type: LessonType.quiz,
        question: 'Qual função parece mais fácil de entender?',
        options: [
          LessonOption(
              text: 'calcular_total(preco, quantidade)', isCorrect: true),
          LessonOption(text: 'fazer_tudo_do_programa()', isCorrect: false),
          LessonOption(text: 'x()', isCorrect: false),
        ],
        hint: 'Bons nomes explicam a responsabilidade da função.',
        xpReward: 20,
        coinReward: 10,
      ),
    ],
  ),
  CourseLevel(
    id: 4,
    title: 'Fluxos reais com Python',
    description: 'Regras, classificações e validações',
    emoji: 'FLOW',
    isLocked: true,
    lessons: [
      Lesson(
        id: 'flow_0',
        title: 'if, elif e else',
        description: 'Mais de dois caminhos',
        type: LessonType.explanation,
        explanation:
            'Use if para o primeiro teste, elif para testes extras e else para o caso final.\n\nIsso é útil para classificar notas, temperaturas, níveis, status e resultados de jogo.',
        codeSnippet:
            'pontos = 80\nif pontos >= 90:\n    print("Ouro")\nelif pontos >= 70:\n    print("Prata")\nelse:\n    print("Bronze")',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'flow_1',
        title: 'Classifique pontos',
        description: 'Use elif na ordem certa',
        type: LessonType.codeChallenge,
        question: 'Complete para pontos = 80 mostrar "Prata":',
        codeTemplate:
            'pontos = 80\nif pontos >= 90:\n    print("Ouro")\n{0} pontos >= 70:\n    print("Prata")\nelse:\n    print("Bronze")',
        availableTokens: ['elif', 'else', 'if', '>='],
        correctTokens: ['elif'],
        expectedOutput: 'Prata',
        hint: 'elif testa uma nova condição depois do if.',
        xpReward: 38,
        coinReward: 19,
      ),
      Lesson(
        id: 'flow_2',
        title: 'Desconto por regra',
        description: 'Aplique uma condição de negócio',
        type: LessonType.codeChallenge,
        question: 'Complete para mostrar "Desconto 20":',
        codeTemplate:
            'compra = 120\nif compra {0} 100:\n    desconto = 20\nelse:\n    desconto = 0\nprint("Desconto", {1})',
        availableTokens: ['>=', '<', 'desconto', 'compra'],
        correctTokens: ['>=', 'desconto'],
        expectedOutput: 'Desconto 20',
        hint: 'Compra 120 passa na regra compra >= 100.',
        xpReward: 40,
        coinReward: 20,
      ),
      Lesson(
        id: 'flow_3',
        title: 'Rastreamento de código',
        description: 'Leia linha por linha antes de executar',
        type: LessonType.quiz,
        question:
            'Se valor = 5 e o código faz valor = valor + 2, qual será valor?',
        options: [
          LessonOption(text: '7', isCorrect: true),
          LessonOption(text: '5', isCorrect: false),
          LessonOption(text: '2', isCorrect: false),
        ],
        hint: 'A variável recebe o valor antigo mais 2.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'flow_4',
        title: 'Loop com acumulador real',
        description: 'Conte pontos em várias rodadas',
        type: LessonType.codeChallenge,
        question: 'Complete para somar 10 pontos em 3 rodadas e mostrar 30:',
        codeTemplate:
            'pontos = 0\nfor rodada in range(3):\n    pontos = pontos {0} 10\nprint({1})',
        availableTokens: ['+', '-', 'pontos', 'rodada'],
        correctTokens: ['+', 'pontos'],
        expectedOutput: '30',
        hint: 'A cada rodada, pontos aumenta em 10.',
        xpReward: 42,
        coinReward: 21,
      ),
      Lesson(
        id: 'flow_5',
        title: 'Regra dentro de função',
        description: 'Nomeie uma validação',
        type: LessonType.codeChallenge,
        question: 'Complete para mostrar "Liberado":',
        codeTemplate:
            'def validar_idade(idade):\n    if idade {0} 18:\n        print("Liberado")\n    else:\n        print("Bloqueado")\n\nvalidar_idade({1})',
        availableTokens: ['>=', '<', '18', '16'],
        correctTokens: ['>=', '18'],
        expectedOutput: 'Liberado',
        hint: 'A função deve liberar idade 18 ou maior.',
        xpReward: 44,
        coinReward: 22,
      ),
    ],
  ),
  CourseLevel(
    id: 5,
    title: 'Mini projetos guiados',
    description: 'Junte lógica, Python e funções',
    emoji: 'PROJ',
    isLocked: true,
    lessons: [
      Lesson(
        id: 'proj_0',
        title: 'Projeto: calculadora de compra',
        description: 'Uma regra completa de total',
        type: LessonType.explanation,
        explanation:
            'Agora você combina variáveis, operadores e funções para resolver um problema real: calcular o total de uma compra.',
        codeSnippet:
            'def total_compra(preco, quantidade):\n    total = preco * quantidade\n    print("Total", total)\n\ntotal_compra(12, 4)',
        xpReward: 24,
        coinReward: 12,
      ),
      Lesson(
        id: 'proj_1',
        title: 'Monte a compra',
        description: 'Complete a função do projeto',
        type: LessonType.codeChallenge,
        question: 'Complete para mostrar "Total 48":',
        codeTemplate:
            'def total_compra(preco, quantidade):\n    total = preco {0} quantidade\n    print("Total", {1})\n\ntotal_compra(12, 4)',
        availableTokens: ['*', '+', 'total', 'preco', 'quantidade'],
        correctTokens: ['*', 'total'],
        expectedOutput: 'Total 48',
        hint: 'preço vezes quantidade.',
        xpReward: 48,
        coinReward: 24,
      ),
      Lesson(
        id: 'proj_2',
        title: 'Projeto: jogo de adivinhação',
        description: 'Compare chute e número secreto',
        type: LessonType.explanation,
        explanation:
            'Um jogo de adivinhação usa comparações para responder ao jogador: acertou, está baixo ou está alto.',
        codeSnippet:
            'secreto = 7\nchute = 5\nif chute == secreto:\n    print("Acertou")\nelif chute < secreto:\n    print("Baixo")\nelse:\n    print("Alto")',
        xpReward: 24,
        coinReward: 12,
      ),
      Lesson(
        id: 'proj_3',
        title: 'Complete o jogo',
        description: 'Use elif para o segundo caminho',
        type: LessonType.codeChallenge,
        question: 'chute = 5 e secreto = 7. Complete para mostrar "Baixo":',
        codeTemplate:
            'secreto = 7\nchute = 5\nif chute {0} secreto:\n    print("Acertou")\n{1} chute < secreto:\n    print("Baixo")\nelse:\n    print("Alto")',
        availableTokens: ['==', '!=', 'elif', 'else', 'if'],
        correctTokens: ['==', 'elif'],
        expectedOutput: 'Baixo',
        hint: '== compara igualdade; elif testa outra condição.',
        xpReward: 48,
        coinReward: 24,
      ),
      Lesson(
        id: 'proj_4',
        title: 'Projeto: rotina de estudos',
        description: 'Classifique o progresso',
        type: LessonType.codeChallenge,
        question: 'Complete para mostrar "Meta batida":',
        codeTemplate:
            'def verificar_estudo(minutos):\n    if minutos {0} 30:\n        print("Meta batida")\n    else:\n        print("Estudar mais")\n\nverificar_estudo({1})',
        availableTokens: ['>=', '<', '30', '15'],
        correctTokens: ['>=', '30'],
        expectedOutput: 'Meta batida',
        hint: 'A meta é atingida com 30 minutos ou mais.',
        xpReward: 50,
        coinReward: 25,
      ),
      Lesson(
        id: 'proj_5',
        title: 'Próximo passo',
        description: 'Como continuar evoluindo',
        type: LessonType.explanation,
        explanation:
            'Você já praticou sequência, condições, loops, acumuladores e funções.\n\nA partir daqui, projetos maiores seguem o mesmo padrão: divida em partes, nomeie bem as funções, teste cada regra e evolua aos poucos.',
        codeSnippet:
            'def resolver_problema():\n    print("1. Entender")\n    print("2. Dividir")\n    print("3. Codar")\n    print("4. Testar")\n\nresolver_problema()',
        xpReward: 28,
        coinReward: 14,
      ),
    ],
  ),
];

bool hasCompletedLogicFoundations(Iterable<String> completedLessons) {
  final completed = completedLessons.toSet();
  final foundationLessons = pythonCurriculum
      .take(logicFoundationLevelCount)
      .expand((level) => level.lessons);

  return foundationLessons.every((lesson) => completed.contains(lesson.id));
}
