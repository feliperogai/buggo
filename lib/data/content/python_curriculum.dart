import '../../shared/models/lesson.dart';

final List<CourseLevel> pythonCurriculum = [
  CourseLevel(
    id: 0,
    title: 'Lógica & Pensamento',
    description: 'Aprenda a pensar como um programador!',
    emoji: '🧠',
    isLocked: false,
    lessons: [
      const Lesson(
        id: 'l0_0',
        title: 'O que é programação?',
        description: 'Entenda o que um computador faz',
        type: LessonType.explanation,
        explanation:
            'Programar é dar instruções para o computador. Como uma receita de bolo: você fala o que fazer, passo a passo, e o computador obedece!\n\nO computador faz exatamente o que você manda — nada mais, nada menos.',
        xpReward: 10,
        coinReward: 5,
      ),
      const Lesson(
        id: 'l0_1',
        title: 'Sequência lógica',
        description: 'A ordem das instruções importa!',
        type: LessonType.quiz,
        question: 'Para fazer um sanduíche, qual é a ordem correta?',
        options: [
          LessonOption(text: 'Pão → Recheio → Fechar', isCorrect: true),
          LessonOption(text: 'Recheio → Pão → Fechar', isCorrect: false),
          LessonOption(text: 'Fechar → Pão → Recheio', isCorrect: false),
        ],
        hint: 'Pense na ordem natural de montar um sanduíche!',
        xpReward: 15,
        coinReward: 8,
      ),
      const Lesson(
        id: 'l0_2',
        title: 'Decisões simples',
        description: 'Quando fazer uma coisa ou outra',
        type: LessonType.quiz,
        question: 'SE está chovendo, o que você faz?',
        options: [
          LessonOption(text: 'Pego o guarda-chuva', isCorrect: true),
          LessonOption(text: 'Vou de chinelo', isCorrect: false),
          LessonOption(text: 'Fico sem roupa', isCorrect: false),
        ],
        explanation:
            'Em programação, usamos IF (SE) para tomar decisões. SE uma condição for verdadeira, faça algo. SENÃO, faça outra coisa.',
        xpReward: 15,
        coinReward: 8,
      ),
      const Lesson(
        id: 'l0_3',
        title: 'Repetição (Loops)',
        description: 'Faça a mesma coisa várias vezes!',
        type: LessonType.quiz,
        question: 'Quantas vezes a instrução "Pule!" se repete no loop?',
        codeSnippet: 'repita 3 vezes:\n    Pule!',
        options: [
          LessonOption(text: '3 vezes', isCorrect: true),
          LessonOption(text: '1 vez', isCorrect: false),
          LessonOption(text: '2 vezes', isCorrect: false),
        ],
        hint: 'O número depois de "repita" é a resposta!',
        xpReward: 20,
        coinReward: 10,
      ),
    ],
  ),

  CourseLevel(
    id: 1,
    title: 'Primeiros Passos em Python',
    description: 'Seu primeiro código de verdade!',
    emoji: '🐍',
    isLocked: true,
    lessons: [
      const Lesson(
        id: 'l1_0',
        title: 'Olá, Python!',
        description: 'Seu primeiro programa',
        type: LessonType.explanation,
        explanation:
            'Python é uma linguagem de programação muito famosa e fácil de aprender!\n\nO comando print() mostra uma mensagem na tela. É como o Python "falar" com você!',
        codeSnippet: 'print("Olá, Mundo!")',
        xpReward: 10,
        coinReward: 5,
      ),

      // CODE FILL: print()
      const Lesson(
        id: 'l1_1',
        title: 'Use o print()',
        description: 'Complete o código para mostrar a mensagem',
        type: LessonType.codeChallenge,
        question: 'Qual função usamos para mostrar texto na tela?',
        codeTemplate: '{0}("Buggo é incrível!")',
        availableTokens: ['print', 'input', 'show', 'display'],
        correctTokens: ['print'],
        expectedOutput: 'Buggo é incrível!',
        hint: 'print() é a função que "imprime" texto na tela',
        xpReward: 20,
        coinReward: 10,
      ),

      const Lesson(
        id: 'l1_2',
        title: 'Variáveis',
        description: 'Guardando informações',
        type: LessonType.explanation,
        explanation:
            'Uma variável é como uma caixinha onde você guarda informação.\n\nVocê dá um nome pra caixinha e coloca um valor dentro!',
        codeSnippet: 'nome = "Buggo"\nidade = 10\nprint(nome)',
        xpReward: 10,
        coinReward: 5,
      ),

      // CODE FILL: variáveis
      const Lesson(
        id: 'l1_3',
        title: 'Criando variáveis',
        description: 'Guarde "banana" em uma variável e mostre',
        type: LessonType.codeChallenge,
        question: 'Crie a variável "fruta" e mostre seu valor na tela:',
        codeTemplate: '{0} = "banana"\nprint({1})',
        availableTokens: ['fruta', 'nome', '"banana"', 'valor'],
        correctTokens: ['fruta', 'fruta'],
        expectedOutput: 'banana',
        hint: 'A variável precisa ter o mesmo nome nas duas linhas!',
        xpReward: 25,
        coinReward: 12,
      ),

      // CODE FILL: operadores aritméticos
      const Lesson(
        id: 'l1_4',
        title: 'Calculando com Python',
        description: 'Use o operador certo para somar',
        type: LessonType.codeChallenge,
        question: 'Complete para que resultado seja 8 (5 + 3):',
        codeTemplate: 'resultado = 5 {0} 3\nprint(resultado)',
        availableTokens: ['+', '-', '*', '/'],
        correctTokens: ['+'],
        expectedOutput: '8',
        hint: 'O operador + soma dois números',
        xpReward: 20,
        coinReward: 10,
      ),

      const Lesson(
        id: 'l1_5',
        title: 'if: Tomando decisões',
        description: 'O Python também decide!',
        type: LessonType.explanation,
        explanation:
            'Com o "if" (SE), o Python pode tomar decisões.\nSE uma condição for verdadeira, ele executa um bloco de código.',
        codeSnippet: 'idade = 18\nif idade >= 18:\n    print("Adulto!")',
        xpReward: 10,
        coinReward: 5,
      ),

      // CODE FILL: if/else
      const Lesson(
        id: 'l1_6',
        title: 'if e else juntos',
        description: 'Complete a estrutura SE/SENÃO',
        type: LessonType.codeChallenge,
        question: 'nota=5 deve imprimir "Reprovado!". Complete:',
        codeTemplate:
            'nota = 5\nif nota {0} 7:\n    print("Aprovado!")\n{1}:\n    print("Reprovado!")',
        availableTokens: ['>=', '<=', 'else', 'elif', '>'],
        correctTokens: ['>=', 'else'],
        expectedOutput: 'Reprovado!',
        hint: '"else" não precisa de condição — é o "senão"',
        xpReward: 30,
        coinReward: 15,
      ),

      const Lesson(
        id: 'l1_7',
        title: 'Loop for',
        description: 'Repetindo com for',
        type: LessonType.explanation,
        explanation:
            'O loop "for" repete um bloco de código várias vezes!\nrange(5) cria os números de 0 a 4.',
        codeSnippet: 'for i in range(3):\n    print("Olá!")',
        xpReward: 10,
        coinReward: 5,
      ),

      // CODE FILL: for + range
      const Lesson(
        id: 'l1_8',
        title: 'Loop for na prática',
        description: 'Complete para imprimir "Python!" 4 vezes',
        type: LessonType.codeChallenge,
        question: 'Use range() para repetir 4 vezes:',
        codeTemplate: 'for i in {0}({1}):\n    print("Python!")',
        availableTokens: ['range', '4', 'lista', '3', 'enumerate'],
        correctTokens: ['range', '4'],
        expectedOutput: 'Python!\nPython!\nPython!\nPython!',
        hint: 'range(4) gera os números 0, 1, 2, 3 — 4 números!',
        xpReward: 30,
        coinReward: 15,
      ),

      const Lesson(
        id: 'l1_9',
        title: 'Funções',
        description: 'Criando seus próprios comandos',
        type: LessonType.explanation,
        explanation:
            'Funções são blocos de código que você cria uma vez e usa várias vezes!\nDef define a função, depois você a "chama" pelo nome.',
        codeSnippet: 'def saudar():\n    print("Olá! Bem-vindo!")\n\nsaudar()',
        xpReward: 15,
        coinReward: 8,
      ),
    ],
  ),

  CourseLevel(
    id: 2,
    title: 'Mini Projetos Reais',
    description: 'Construa coisas de verdade!',
    emoji: '🚀',
    isLocked: true,
    lessons: [
      const Lesson(
        id: 'l2_0',
        title: 'Calculadora Simples',
        description: 'Seu primeiro mini projeto!',
        type: LessonType.explanation,
        explanation:
            'Vamos criar uma calculadora! Ela some dois números e mostra o resultado.',
        codeSnippet:
            'def calcular(a, b):\n    soma = a + b\n    print("Resultado:", soma)\n\ncalcular(10, 5)',
        xpReward: 30,
        coinReward: 15,
      ),

      // CODE FILL: calculadora
      const Lesson(
        id: 'l2_1',
        title: 'Monte a Calculadora',
        description: 'Complete a função para somar e mostrar o resultado',
        type: LessonType.codeChallenge,
        question: 'Complete para que calcular(10, 5) mostre "Resultado: 15":',
        codeTemplate:
            'def calcular(a, b):\n    soma = a {0} b\n    print("Resultado:", {1})\n\ncalcular(10, 5)',
        availableTokens: ['+', '-', 'soma', 'a', 'b'],
        correctTokens: ['+', 'soma'],
        expectedOutput: 'Resultado: 15',
        hint: 'Somamos a + b e depois mostramos a variável "soma"',
        xpReward: 40,
        coinReward: 20,
      ),

      const Lesson(
        id: 'l2_2',
        title: 'Jogo de Adivinhação',
        description: 'Lógica de jogo simples',
        type: LessonType.explanation,
        explanation:
            'Um jogo onde o computador tem um número secreto e você tenta adivinhar!\nÉ o if/elif/else em ação.',
        codeSnippet:
            'secreto = 7\nchute = 5\n\nif chute == secreto:\n    print("Acertou!")\nelif chute < secreto:\n    print("Muito baixo!")\nelse:\n    print("Muito alto!")',
        xpReward: 30,
        coinReward: 15,
      ),

      // CODE FILL: adivinhação
      const Lesson(
        id: 'l2_3',
        title: 'Complete o Jogo',
        description: 'Complete a lógica do jogo de adivinhação',
        type: LessonType.codeChallenge,
        question: 'chute=5 e secreto=7. Complete para mostrar "Muito baixo!":',
        codeTemplate:
            'secreto = 7\nchute = 5\n\nif chute {0} secreto:\n    print("Acertou!")\n{1} chute < secreto:\n    print("Muito baixo!")\nelse:\n    print("Muito alto!")',
        availableTokens: ['==', '!=', 'elif', 'else', 'if'],
        correctTokens: ['==', 'elif'],
        expectedOutput: 'Muito baixo!',
        hint: '== compara igualdade; elif é "senão se" com condição',
        xpReward: 40,
        coinReward: 20,
      ),
    ],
  ),
];
