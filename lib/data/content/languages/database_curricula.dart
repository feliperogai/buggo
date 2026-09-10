import '../../../shared/models/lesson.dart';

/// Trilha do módulo **Banco de dados**: consultas SQL.
///
/// Começa do zero e não depende de nenhuma outra trilha. Os desafios de
/// código não passam pelo `PythonSimulator`, então `expectedOutput` fica nulo
/// e a correção é a montagem da consulta — ver `challenge_screen.dart`.

const List<CourseLevel> queriesCurriculum = [
  CourseLevel(
    id: 0,
    languageId: 'queries',
    title: 'Consultas: primeiros passos',
    description: 'Perguntar ao banco e receber a resposta',
    emoji: 'SQL',
    isLocked: false,
    lessons: [
      Lesson(
        id: 'sql_basic_0',
        title: 'SQL é uma pergunta bem feita',
        description: 'Você descreve o que quer, não como buscar',
        type: LessonType.explanation,
        explanation:
            'Em SQL você não manda o banco percorrer linha por linha. Você descreve o resultado que quer, e ele decide o caminho mais rápido.\n\nÉ a linguagem que quase todo sistema usa para guardar dado — inclusive o Buggo, que guarda contas e ranking em Postgres.',
        codeSnippet: 'SELECT nome, xp FROM usuarios ORDER BY xp DESC LIMIT 10;',
        xpReward: 12,
        coinReward: 6,
      ),
      Lesson(
        id: 'sql_basic_1',
        title: 'Escolhendo colunas',
        description: 'O SELECT',
        type: LessonType.quiz,
        question: 'Como trazer só o nome e o e-mail da tabela usuarios?',
        options: [
          LessonOption(
              text: 'SELECT nome, email FROM usuarios;', isCorrect: true),
          LessonOption(text: 'GET nome, email FROM usuarios;', isCorrect: false),
          LessonOption(text: 'SELECT usuarios(nome, email);', isCorrect: false),
        ],
        hint: 'Primeiro o que você quer, depois de onde vem.',
        xpReward: 14,
        coinReward: 7,
      ),
      Lesson(
        id: 'sql_basic_2',
        title: 'Filtrando linhas',
        description: 'Complete a condição',
        type: LessonType.codeChallenge,
        question: 'Traga apenas os usuários com mais de 100 de XP.',
        codeTemplate: 'SELECT nome FROM usuarios\n{0} xp {1} 100;',
        availableTokens: ['WHERE', 'IF', '>', '='],
        correctTokens: ['WHERE', '>'],
        hint: '"Mais de 100" não inclui o 100.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'sql_basic_3',
        title: 'Ordenando o resultado',
        description: 'Do maior para o menor',
        type: LessonType.quiz,
        question: 'Como ordenar do maior XP para o menor?',
        options: [
          LessonOption(text: 'ORDER BY xp DESC', isCorrect: true),
          LessonOption(text: 'ORDER BY xp ASC', isCorrect: false),
          LessonOption(text: 'SORT BY xp DESC', isCorrect: false),
        ],
        hint: '"Descending" é do maior para o menor.',
        xpReward: 14,
        coinReward: 7,
      ),
      Lesson(
        id: 'sql_basic_4',
        title: 'Só os primeiros',
        description: 'Complete o limite',
        type: LessonType.codeChallenge,
        question: 'Traga apenas os 10 primeiros do ranking.',
        codeTemplate:
            'SELECT nome, xp FROM usuarios\nORDER BY xp DESC\n{0} 10;',
        availableTokens: ['LIMIT', 'TOP', 'FIRST', 'MAX'],
        correctTokens: ['LIMIT'],
        hint: 'É a palavra que o Postgres e o MySQL usam.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'sql_basic_5',
        title: 'O vazio tem nome',
        description: 'Comparando com NULL',
        type: LessonType.quiz,
        question: 'Como buscar usuários sem foto cadastrada?',
        options: [
          LessonOption(text: 'WHERE foto IS NULL', isCorrect: true),
          LessonOption(text: 'WHERE foto = NULL', isCorrect: false),
          LessonOption(text: 'WHERE foto = ""', isCorrect: false),
        ],
        hint: 'NULL não é igual a nada, nem a ele mesmo. Por isso existe o IS.',
        xpReward: 18,
        coinReward: 9,
      ),
    ],
  ),
  CourseLevel(
    id: 1,
    languageId: 'queries',
    title: 'Consultas na prática',
    description: 'Contar, agrupar e juntar tabelas',
    emoji: 'JOIN',
    lessons: [
      Lesson(
        id: 'sql_pratica_0',
        title: 'Contando linhas',
        description: 'A função de agregação',
        type: LessonType.quiz,
        question: 'Como saber quantos usuários existem?',
        options: [
          LessonOption(text: 'SELECT COUNT(*) FROM usuarios;', isCorrect: true),
          LessonOption(text: 'SELECT SIZE(usuarios);', isCorrect: false),
          LessonOption(text: 'SELECT LENGTH(usuarios);', isCorrect: false),
        ],
        hint: 'Conta as linhas que sobraram depois do filtro.',
        xpReward: 16,
        coinReward: 8,
      ),
      Lesson(
        id: 'sql_pratica_1',
        title: 'Somando por grupo',
        description: 'Complete o agrupamento',
        type: LessonType.codeChallenge,
        question: 'Some o XP de cada linguagem estudada.',
        codeTemplate:
            'SELECT linguagem, {0}(xp)\nFROM usuarios\n{1} linguagem;',
        availableTokens: ['SUM', 'COUNT', 'GROUP BY', 'ORDER BY'],
        correctTokens: ['SUM', 'GROUP BY'],
        hint: 'Uma linha por linguagem: o agrupamento define isso.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'sql_pratica_2',
        title: 'WHERE ou HAVING',
        description: 'Filtro antes ou depois de agrupar',
        type: LessonType.quiz,
        question:
            'Você quer só os grupos cuja soma passa de 1000. Onde vai esse filtro?',
        options: [
          LessonOption(text: 'HAVING SUM(xp) > 1000', isCorrect: true),
          LessonOption(text: 'WHERE SUM(xp) > 1000', isCorrect: false),
          LessonOption(text: 'ORDER BY SUM(xp) > 1000', isCorrect: false),
        ],
        hint: 'WHERE filtra linhas; o outro filtra grupos já formados.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'sql_pratica_3',
        title: 'Juntando duas tabelas',
        description: 'Complete o JOIN',
        type: LessonType.codeChallenge,
        question: 'Junte cada compra ao usuário que a fez.',
        codeTemplate:
            'SELECT u.nome, c.produto\nFROM usuarios u\n{0} compras c {1} c.user_id = u.id;',
        availableTokens: ['JOIN', 'MERGE', 'ON', 'WHERE'],
        correctTokens: ['JOIN', 'ON'],
        hint: 'O `ON` diz qual coluna liga uma tabela à outra.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'sql_pratica_4',
        title: 'Quando faltar o par',
        description: 'LEFT JOIN',
        type: LessonType.quiz,
        question:
            'Você quer todos os usuários, mesmo os que nunca compraram nada. Qual usar?',
        options: [
          LessonOption(text: 'LEFT JOIN', isCorrect: true),
          LessonOption(text: 'INNER JOIN', isCorrect: false),
          LessonOption(text: 'CROSS JOIN', isCorrect: false),
        ],
        hint: 'O INNER descarta quem não tem par do outro lado.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'sql_pratica_5',
        title: 'Para onde ir agora',
        description: 'O que praticar depois',
        type: LessonType.explanation,
        explanation:
            'Dois assuntos rendem muito daqui em diante: índices, que fazem uma consulta lenta virar instantânea, e consultas preparadas, que impedem injeção de SQL.\n\nE uma regra que vale para sempre: antes de rodar um UPDATE ou DELETE, rode a mesma condição num SELECT e veja quantas linhas viriam.',
        xpReward: 14,
        coinReward: 7,
      ),
    ],
  ),
  CourseLevel(
    id: 2,
    languageId: 'queries',
    title: 'Consultas: mudando dados com segurança',
    description: 'INSERT, UPDATE, DELETE, NULL e subconsultas',
    emoji: 'UPD',
    lessons: [
      Lesson(
        id: 'sql_alem_0',
        title: 'Ler é seguro, escrever não',
        description: 'A diferença que custa caro',
        type: LessonType.explanation,
        explanation:
            'Um SELECT errado devolve a resposta errada. Um UPDATE errado muda o banco, e não existe desfazer.\n\nA disciplina é sempre a mesma: escreva a condição num SELECT primeiro, confira quantas linhas aparecem, e só então troque a palavra inicial pelo UPDATE ou DELETE.',
        codeSnippet:
            '-- 1. conferir\nSELECT * FROM usuarios WHERE id = 7;\n\n-- 2. só depois\nUPDATE usuarios SET coins = 200 WHERE id = 7;',
        xpReward: 16,
        coinReward: 8,
      ),
      Lesson(
        id: 'sql_alem_1',
        title: 'Inserindo uma linha',
        description: 'Complete o comando',
        type: LessonType.codeChallenge,
        question: 'Cadastre um usuário chamado Ana.',
        codeTemplate:
            '{0} usuarios (nome, coins)\n{1} ("Ana", 0);',
        availableTokens: ['INSERT INTO', 'ADD TO', 'VALUES', 'SET'],
        correctTokens: ['INSERT INTO', 'VALUES'],
        hint: 'Primeiro as colunas, depois os valores na mesma ordem.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'sql_alem_2',
        title: 'O DELETE sem WHERE',
        description: 'O erro mais caro do SQL',
        type: LessonType.quiz,
        question: 'O que `DELETE FROM usuarios;` faz?',
        options: [
          LessonOption(text: 'Apaga todas as linhas da tabela', isCorrect: true),
          LessonOption(text: 'Não faz nada, falta o WHERE', isCorrect: false),
          LessonOption(text: 'Apaga só a primeira linha', isCorrect: false),
        ],
        hint: 'Sem filtro, o comando vale para a tabela inteira.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'sql_alem_3',
        title: 'Comparando com o vazio',
        description: 'Complete a condição',
        type: LessonType.codeChallenge,
        question: 'Selecione os usuários que ainda não preencheram o e-mail.',
        codeTemplate: 'SELECT nome\nFROM usuarios\nWHERE email {0};',
        availableTokens: ['IS NULL', '= NULL', '== NULL', 'IS EMPTY'],
        correctTokens: ['IS NULL'],
        hint: 'NULL não é igual a nada, nem a ele mesmo. Por isso existe um operador só para ele.',
        xpReward: 20,
        coinReward: 10,
      ),
      Lesson(
        id: 'sql_alem_4',
        title: 'Os dez primeiros',
        description: 'Ordenar e cortar',
        type: LessonType.quiz,
        question: 'Qual consulta traz os 10 usuários com mais moedas?',
        options: [
          LessonOption(
              text: 'SELECT * FROM usuarios ORDER BY coins DESC LIMIT 10;',
              isCorrect: true),
          LessonOption(
              text: 'SELECT TOP 10 * FROM usuarios ORDER BY coins;', isCorrect: false),
          LessonOption(
              text: 'SELECT * FROM usuarios LIMIT 10 ORDER BY coins DESC;',
              isCorrect: false),
        ],
        hint: 'Ordena primeiro, corta depois. E DESC é do maior para o menor.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'sql_alem_5',
        title: 'Tudo ou nada',
        description: 'Para que serve uma transação',
        type: LessonType.explanation,
        explanation:
            'Transferir moedas de uma conta para outra são dois comandos: tirar de um, somar no outro. Se o servidor cair no meio, o dinheiro some.\n\nA transação resolve: entre BEGIN e COMMIT, ou tudo acontece, ou nada acontece. Um ROLLBACK desfaz o que estava no meio.',
        codeSnippet:
            'BEGIN;\n\nUPDATE contas SET saldo = saldo - 100 WHERE id = 1;\nUPDATE contas SET saldo = saldo + 100 WHERE id = 2;\n\nCOMMIT;',
        xpReward: 18,
        coinReward: 9,
      ),
    ],
  ),
];
