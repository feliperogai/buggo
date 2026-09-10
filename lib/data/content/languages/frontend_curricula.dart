import '../../../shared/models/lesson.dart';

/// Trilhas do módulo **Frontend**: JavaScript e TypeScript.
///
/// Cada linguagem começa do zero — nenhuma depende de ter terminado outra
/// trilha. Quem já programa pula direto para a linguagem que quiser.
///
/// Os desafios de código destas trilhas não passam pelo `PythonSimulator`
/// (ele só entende Python): `expectedOutput` fica nulo e a correção é a
/// montagem do trecho. Ver `challenge_screen.dart`.

const List<CourseLevel> javascriptCurriculum = [
  CourseLevel(
    id: 0,
    languageId: 'javascript',
    title: 'JavaScript: primeiros passos',
    description: 'A linguagem que roda dentro de todo navegador',
    emoji: 'JS',
    isLocked: false,
    lessons: [
      Lesson(
        id: 'js_basic_0',
        title: 'Onde o JavaScript vive',
        description: 'Por que ele está em toda página',
        type: LessonType.explanation,
        explanation:
            'JavaScript é a linguagem que o navegador entende. Todo botão que responde ao toque, menu que abre e formulário que valida antes de enviar passa por ela.\n\nEle também roda fora do navegador, no Node.js, movendo servidores e APIs. Uma linguagem só, dos dois lados.',
        codeSnippet: 'console.log("Olá, Buggo!");',
        xpReward: 12,
        coinReward: 6,
      ),
      Lesson(
        id: 'js_basic_1',
        title: 'Mostrando na tela',
        description: 'A primeira saída',
        type: LessonType.quiz,
        question: 'Qual comando escreve uma mensagem no console do navegador?',
        options: [
          LessonOption(text: 'console.log("Oi")', isCorrect: true),
          LessonOption(text: 'print("Oi")', isCorrect: false),
          LessonOption(text: 'echo "Oi"', isCorrect: false),
        ],
        hint: 'É o "log" do console.',
        xpReward: 14,
        coinReward: 7,
      ),
      Lesson(
        id: 'js_basic_2',
        title: 'Guardando um valor',
        description: 'Monte a linha que cria a variável',
        type: LessonType.codeChallenge,
        question: 'Crie a variável `nome` com o texto "Ana" e mostre no console.',
        codeTemplate: '{0} nome = {1};\nconsole.log(nome);',
        availableTokens: ['let', 'var', '"Ana"', 'Ana', 'def'],
        correctTokens: ['let', '"Ana"'],
        hint: '`let` cria a variável. Texto sempre entre aspas.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'js_basic_3',
        title: 'let, const ou var',
        description: 'Qual usar para um valor que não muda',
        type: LessonType.quiz,
        question:
            'Você quer guardar a taxa de juros, que não deve mudar depois. Qual palavra usar?',
        options: [
          LessonOption(text: 'const', isCorrect: true),
          LessonOption(text: 'let', isCorrect: false),
          LessonOption(text: 'var', isCorrect: false),
        ],
        hint: '"Constante" é justamente o que não muda.',
        xpReward: 14,
        coinReward: 7,
      ),
      Lesson(
        id: 'js_basic_4',
        title: 'Decidindo com if',
        description: 'Complete a condição',
        type: LessonType.codeChallenge,
        question: 'Mostre "maior de idade" quando a idade for 18 ou mais.',
        codeTemplate:
            'const idade = 20;\nif (idade {0} 18) {\n  console.log("maior de idade");\n}',
        availableTokens: ['>=', '=', '<', '=<'],
        correctTokens: ['>='],
        hint: '"18 ou mais" é maior ou igual.',
        xpReward: 16,
        coinReward: 8,
      ),
      Lesson(
        id: 'js_basic_5',
        title: 'Comparação que não engana',
        description: 'Por que existem dois iguais e três',
        type: LessonType.quiz,
        question: 'Em JavaScript, qual comparação confere valor E tipo?',
        options: [
          LessonOption(text: '===', isCorrect: true),
          LessonOption(text: '==', isCorrect: false),
          LessonOption(text: '=', isCorrect: false),
        ],
        hint: 'O `==` converte tipos antes de comparar. O outro não.',
        xpReward: 16,
        coinReward: 8,
      ),
    ],
  ),
  CourseLevel(
    id: 1,
    languageId: 'javascript',
    title: 'JavaScript na prática',
    description: 'Repetição, funções e listas',
    emoji: 'FN',
    lessons: [
      Lesson(
        id: 'js_pratica_0',
        title: 'Repetindo sem copiar e colar',
        description: 'Qual laço percorre uma lista',
        type: LessonType.quiz,
        question: 'Qual forma percorre cada item de um array chamado `notas`?',
        options: [
          LessonOption(text: 'for (const n of notas) { ... }', isCorrect: true),
          LessonOption(text: 'for n in notas: ...', isCorrect: false),
          LessonOption(text: 'foreach (notas as n) { ... }', isCorrect: false),
        ],
        hint: 'Em JavaScript é `of` para valores.',
        xpReward: 16,
        coinReward: 8,
      ),
      Lesson(
        id: 'js_pratica_1',
        title: 'Contando de 1 a 3',
        description: 'Complete o laço',
        type: LessonType.codeChallenge,
        question: 'Monte o laço que mostra os números 1, 2 e 3.',
        codeTemplate:
            'for (let i = 1; i {0} 3; i{1}) {\n  console.log(i);\n}',
        availableTokens: ['<=', '<', '++', '--'],
        correctTokens: ['<=', '++'],
        hint: 'Precisa incluir o 3 e somar um a cada volta.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'js_pratica_2',
        title: 'Empacotando em função',
        description: 'Um nome para um trecho de código',
        type: LessonType.quiz,
        question: 'Qual declara uma função chamada `somar` com dois parâmetros?',
        options: [
          LessonOption(text: 'function somar(a, b) { ... }', isCorrect: true),
          LessonOption(text: 'def somar(a, b): ...', isCorrect: false),
          LessonOption(text: 'func somar(a, b) { ... }', isCorrect: false),
        ],
        hint: 'A palavra é a mesma que em inglês significa "função".',
        xpReward: 16,
        coinReward: 8,
      ),
      Lesson(
        id: 'js_pratica_3',
        title: 'Devolvendo um resultado',
        description: 'Complete a função',
        type: LessonType.codeChallenge,
        question: 'A função precisa devolver a soma dos dois números.',
        codeTemplate:
            'function somar(a, b) {\n  {0} a {1} b;\n}\nconsole.log(somar(2, 3));',
        availableTokens: ['return', 'print', '+', '-'],
        correctTokens: ['return', '+'],
        hint: 'Sem `return` a função não entrega nada de volta.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'js_pratica_4',
        title: 'Listas que crescem',
        description: 'Adicionando ao fim de um array',
        type: LessonType.quiz,
        question: 'Como adicionar "uva" ao fim do array `frutas`?',
        options: [
          LessonOption(text: 'frutas.push("uva")', isCorrect: true),
          LessonOption(text: 'frutas.append("uva")', isCorrect: false),
          LessonOption(text: 'frutas.add("uva")', isCorrect: false),
        ],
        hint: 'É o verbo "empurrar" em inglês.',
        xpReward: 16,
        coinReward: 8,
      ),
      Lesson(
        id: 'js_pratica_5',
        title: 'Para onde ir agora',
        description: 'O que praticar depois',
        type: LessonType.explanation,
        explanation:
            'Com variáveis, condições, laços, funções e arrays já dá para escrever coisa útil.\n\nO passo seguinte no navegador é mexer na página: pegar um elemento com `document.querySelector` e reagir a um clique com `addEventListener`. Do lado do servidor, é ler dados de uma API com `fetch`.',
        xpReward: 14,
        coinReward: 7,
      ),
    ],
  ),
  CourseLevel(
    id: 2,
    languageId: 'javascript',
    title: 'JavaScript: dados de verdade',
    description: 'Objetos, listas que se transformam e dados que vêm de fora',
    emoji: 'OB',
    lessons: [
      Lesson(
        id: 'js_alem_0',
        title: 'Um objeto guarda vários campos',
        description: 'Quando uma variável não basta',
        type: LessonType.explanation,
        explanation:
            'Guardar o nome, a idade e o e-mail de alguém em três variáveis separadas funciona até aparecer a segunda pessoa. Objeto resolve isso: um valor só, com campos nomeados dentro.\n\nCada campo tem uma chave e um valor. Você lê pelo nome da chave, não pela posição — é o que torna o código legível seis meses depois.',
        codeSnippet:
            'const aluno = {\n  nome: "Ana",\n  idade: 16,\n};\n\nconsole.log(aluno.nome);',
        xpReward: 14,
        coinReward: 7,
      ),
      Lesson(
        id: 'js_alem_1',
        title: 'Lendo um campo',
        description: 'O ponto entre o objeto e a chave',
        type: LessonType.quiz,
        question:
            'O objeto `livro` tem o campo `titulo`. Como você lê esse valor?',
        options: [
          LessonOption(text: 'livro.titulo', isCorrect: true),
          LessonOption(text: 'livro->titulo', isCorrect: false),
          LessonOption(text: 'livro::titulo', isCorrect: false),
        ],
        hint: 'Em JavaScript é sempre o ponto.',
        xpReward: 14,
        coinReward: 7,
      ),
      Lesson(
        id: 'js_alem_2',
        title: 'Transformando uma lista',
        description: 'Monte a linha que dobra cada nota',
        type: LessonType.codeChallenge,
        question:
            'A partir de `notas`, crie `dobradas` com cada valor multiplicado por 2.',
        codeTemplate:
            'const notas = [5, 7, 9];\nconst dobradas = notas.{0}(n => n * 2);\nconsole.log(dobradas);',
        availableTokens: ['map', 'filter', 'push', 'forEach'],
        correctTokens: ['map'],
        hint: 'É o que devolve uma lista nova, do mesmo tamanho.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'js_alem_3',
        title: 'map ou filter',
        description: 'Duas ferramentas parecidas, usos diferentes',
        type: LessonType.quiz,
        question:
            'Você quer só as notas maiores que 7, e nada além disso. Qual método usar?',
        options: [
          LessonOption(text: 'filter', isCorrect: true),
          LessonOption(text: 'map', isCorrect: false),
          LessonOption(text: 'sort', isCorrect: false),
        ],
        hint: 'Um transforma cada item, o outro escolhe quais ficam.',
        xpReward: 16,
        coinReward: 8,
      ),
      Lesson(
        id: 'js_alem_4',
        title: 'Texto que vira objeto',
        description: 'Complete a leitura do JSON',
        type: LessonType.codeChallenge,
        question:
            'A API devolveu um texto JSON. Transforme em objeto para poder ler os campos.',
        codeTemplate:
            'const texto = "{\\"nome\\": \\"Ana\\"}";\nconst dados = JSON.{0}(texto);\nconsole.log(dados.nome);',
        availableTokens: ['parse', 'stringify', 'read', 'toObject'],
        correctTokens: ['parse'],
        hint: 'Analisar o texto é "parse". O caminho contrário é "stringify".',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'js_alem_5',
        title: 'Coisas que demoram',
        description: 'Por que existe async e await',
        type: LessonType.explanation,
        explanation:
            'Buscar dados na internet leva tempo. Se o navegador ficasse parado esperando, a página travava a cada requisição.\n\nPor isso essas funções devolvem uma promessa de resposta. `await` diz "siga daqui quando a resposta chegar", e ele só pode aparecer dentro de uma função marcada com `async`.',
        codeSnippet:
            'async function carregar() {\n  const resposta = await fetch("/api/notas");\n  const notas = await resposta.json();\n  console.log(notas);\n}',
        xpReward: 16,
        coinReward: 8,
      ),
    ],
  ),
];

const List<CourseLevel> typescriptCurriculum = [
  CourseLevel(
    id: 0,
    languageId: 'typescript',
    title: 'TypeScript: primeiros passos',
    description: 'JavaScript que avisa o erro antes de rodar',
    emoji: 'TS',
    isLocked: false,
    lessons: [
      Lesson(
        id: 'ts_basic_0',
        title: 'Por que existe TypeScript',
        description: 'O erro que aparece enquanto você escreve',
        type: LessonType.explanation,
        explanation:
            'TypeScript é JavaScript com tipos. Você diz que uma variável guarda texto, e a ferramenta avisa na hora se alguém tentar colocar um número ali.\n\nO ganho aparece em projeto grande: o erro sai enquanto você escreve, e não na mão do usuário. No fim, tudo vira JavaScript comum para rodar.',
        codeSnippet: 'const nome: string = "Ana";',
        xpReward: 12,
        coinReward: 6,
      ),
      Lesson(
        id: 'ts_basic_1',
        title: 'Anotando o tipo',
        description: 'Onde o tipo entra na linha',
        type: LessonType.quiz,
        question: 'Como declarar `idade` como número?',
        options: [
          LessonOption(text: 'let idade: number = 20;', isCorrect: true),
          LessonOption(text: 'let number idade = 20;', isCorrect: false),
          LessonOption(text: 'int idade = 20;', isCorrect: false),
        ],
        hint: 'O tipo vem depois do nome, separado por dois pontos.',
        xpReward: 14,
        coinReward: 7,
      ),
      Lesson(
        id: 'ts_basic_2',
        title: 'Função com tipos',
        description: 'Complete a assinatura',
        type: LessonType.codeChallenge,
        question: 'A função recebe dois números e devolve um número.',
        codeTemplate:
            'function somar(a: {0}, b: {0}): {0} {\n  return a + b;\n}',
        availableTokens: ['number', 'string', 'int', 'float'],
        correctTokens: ['number'],
        hint: 'Em TypeScript não existe int nem float: número é um tipo só.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'ts_basic_3',
        title: 'Os três tipos do dia a dia',
        description: 'Texto, número e verdadeiro/falso',
        type: LessonType.quiz,
        question: 'Qual tipo guarda verdadeiro ou falso?',
        options: [
          LessonOption(text: 'boolean', isCorrect: true),
          LessonOption(text: 'bool', isCorrect: false),
          LessonOption(text: 'binary', isCorrect: false),
        ],
        hint: 'O nome vem por extenso, de George Boole.',
        xpReward: 14,
        coinReward: 7,
      ),
      Lesson(
        id: 'ts_basic_4',
        title: 'Desenhando um objeto',
        description: 'Complete a interface',
        type: LessonType.codeChallenge,
        question: 'Descreva um usuário com nome (texto) e idade (número).',
        codeTemplate:
            '{0} Usuario {\n  nome: {1};\n  idade: number;\n}',
        availableTokens: ['interface', 'class', 'string', 'text'],
        correctTokens: ['interface', 'string'],
        hint: 'A palavra descreve o formato de um objeto, sem criar código.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'ts_basic_5',
        title: 'Lista com tipo',
        description: 'Como dizer "lista de números"',
        type: LessonType.quiz,
        question: 'Qual declara uma lista de números?',
        options: [
          LessonOption(text: 'let notas: number[] = [];', isCorrect: true),
          LessonOption(text: 'let notas: [number] = [];', isCorrect: false),
          LessonOption(text: 'let notas: list<number> = [];', isCorrect: false),
        ],
        hint: 'Os colchetes vêm depois do tipo do item.',
        xpReward: 16,
        coinReward: 8,
      ),
    ],
  ),
  CourseLevel(
    id: 1,
    languageId: 'typescript',
    title: 'TypeScript na prática',
    description: 'Nulos, uniões e código que não quebra',
    emoji: 'SAFE',
    lessons: [
      Lesson(
        id: 'ts_pratica_0',
        title: 'Pode ser nulo',
        description: 'O tipo que aceita ausência',
        type: LessonType.quiz,
        question:
            'Um campo que pode não existir, guardando texto ou nada. Qual tipo?',
        options: [
          LessonOption(text: 'string | null', isCorrect: true),
          LessonOption(text: 'string?', isCorrect: false),
          LessonOption(text: 'nullable string', isCorrect: false),
        ],
        hint: 'A barra vertical é "ou".',
        xpReward: 16,
        coinReward: 8,
      ),
      Lesson(
        id: 'ts_pratica_1',
        title: 'Parâmetro opcional',
        description: 'Complete a função',
        type: LessonType.codeChallenge,
        question: 'O sobrenome é opcional: quem chamar pode não passar.',
        codeTemplate:
            'function saudar(nome: string, sobrenome{0}: string) {\n  return "Olá " + nome;\n}',
        availableTokens: ['?', '!', '*', '&'],
        correctTokens: ['?'],
        hint: 'A interrogação marca o que pode faltar.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'ts_pratica_2',
        title: 'Um valor entre poucos',
        description: 'Quando só três textos são válidos',
        type: LessonType.quiz,
        question:
            'Um status só pode ser "ativo", "pausado" ou "cancelado". Como escrever o tipo?',
        options: [
          LessonOption(
              text: 'type Status = "ativo" | "pausado" | "cancelado";',
              isCorrect: true),
          LessonOption(text: 'type Status = string[3];', isCorrect: false),
          LessonOption(text: 'enum Status = ("ativo", "pausado");', isCorrect: false),
        ],
        hint: 'União de textos exatos. O editor passa a completar sozinho.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'ts_pratica_3',
        title: 'Só leitura',
        description: 'Complete a propriedade travada',
        type: LessonType.codeChallenge,
        question: 'O id não pode ser alterado depois de criado.',
        codeTemplate: 'interface Conta {\n  {0} id: string;\n  saldo: number;\n}',
        availableTokens: ['readonly', 'const', 'final', 'private'],
        correctTokens: ['readonly'],
        hint: 'É literalmente "somente leitura", em uma palavra.',
        xpReward: 18,
        coinReward: 9,
      ),
      Lesson(
        id: 'ts_pratica_4',
        title: 'O tipo que desliga tudo',
        description: 'Por que evitar o any',
        type: LessonType.quiz,
        question: 'O que acontece ao marcar uma variável como `any`?',
        options: [
          LessonOption(
              text: 'O TypeScript para de checar aquele valor',
              isCorrect: true),
          LessonOption(text: 'A variável aceita só números', isCorrect: false),
          LessonOption(text: 'O código roda mais rápido', isCorrect: false),
        ],
        hint: 'Você volta a ter JavaScript puro naquele ponto.',
        xpReward: 16,
        coinReward: 8,
      ),
      Lesson(
        id: 'ts_pratica_5',
        title: 'Para onde ir agora',
        description: 'O que praticar depois',
        type: LessonType.explanation,
        explanation:
            'Tipos existem para o editor te ajudar: ele completa nomes, mostra o que a função devolve e recusa o erro antes de rodar.\n\nO próximo passo é tipar a resposta de uma API e ver o editor apontando cada campo que você esqueceu de tratar. É onde o TypeScript economiza mais tempo.',
        xpReward: 14,
        coinReward: 7,
      ),
    ],
  ),
  CourseLevel(
    id: 2,
    languageId: 'typescript',
    title: 'TypeScript: tipos que se combinam',
    description: 'Uniões, genéricos e o editor trabalhando por você',
    emoji: 'TC',
    lessons: [
      Lesson(
        id: 'ts_alem_0',
        title: 'Um valor, dois tipos possíveis',
        description: 'O tipo união',
        type: LessonType.explanation,
        explanation:
            'Às vezes um campo pode legitimamente ser de dois tipos. O identificador de um pedido pode chegar como número do banco ou como texto da URL.\n\nA barra vertical descreve exatamente isso. E o TypeScript passa a cobrar: antes de usar como texto, você tem que provar que é texto.',
        codeSnippet:
            'let id: number | string;\n\nid = 42;\nid = "42";',
        xpReward: 14,
        coinReward: 7,
      ),
      Lesson(
        id: 'ts_alem_1',
        title: 'Separando os casos',
        description: 'Como provar de que tipo é',
        type: LessonType.quiz,
        question:
            'Dentro de uma função, `valor` é `string | number`. O que confere se ele é texto agora?',
        options: [
          LessonOption(text: 'typeof valor === "string"', isCorrect: true),
          LessonOption(text: 'valor instanceof String', isCorrect: false),
          LessonOption(text: 'valor.isString()', isCorrect: false),
        ],
        hint: 'Para tipos básicos, o operador é o mesmo do JavaScript.',
        xpReward: 16,
        coinReward: 8,
      ),
      Lesson(
        id: 'ts_alem_2',
        title: 'Função que serve para qualquer tipo',
        description: 'Complete o genérico',
        type: LessonType.codeChallenge,
        question:
            'A função devolve o primeiro item de qualquer lista, mantendo o tipo dos itens.',
        codeTemplate:
            'function primeiro<T>(lista: T[]): {0} {\n  return lista[0];\n}',
        availableTokens: ['T', 'any', 'void', 'unknown'],
        correctTokens: ['T'],
        hint:
            'Devolve um item da lista, então é o mesmo tipo que está dentro dela.',
        xpReward: 20,
        coinReward: 10,
      ),
      Lesson(
        id: 'ts_alem_3',
        title: 'any apaga o TypeScript',
        description: 'O tipo que desliga a checagem',
        type: LessonType.quiz,
        question: 'Por que trocar `T` por `any` no exemplo anterior é ruim?',
        options: [
          LessonOption(
              text: 'O editor perde o tipo e para de avisar erros', isCorrect: true),
          LessonOption(text: 'O código deixa de compilar', isCorrect: false),
          LessonOption(text: 'A função fica mais lenta', isCorrect: false),
        ],
        hint: 'O custo do `any` é sempre o mesmo: você fica sem rede.',
        xpReward: 16,
        coinReward: 8,
      ),
      Lesson(
        id: 'ts_alem_4',
        title: 'Todos os campos opcionais',
        description: 'Monte o tipo utilitário',
        type: LessonType.codeChallenge,
        question:
            'A função de edição recebe só os campos que mudaram do tipo `Aluno`.',
        codeTemplate:
            'interface Aluno {\n  nome: string;\n  idade: number;\n}\n\nfunction editar(mudancas: {0}<Aluno>) {}',
        availableTokens: ['Partial', 'Readonly', 'Record', 'Required'],
        correctTokens: ['Partial'],
        hint: 'Parte do objeto, não o objeto inteiro.',
        xpReward: 20,
        coinReward: 10,
      ),
      Lesson(
        id: 'ts_alem_5',
        title: 'Tipando o que vem da API',
        description: 'Onde o TypeScript paga por si',
        type: LessonType.explanation,
        explanation:
            'A resposta de uma API chega como `any` por padrão. Descrever o formato esperado num tipo faz o editor apontar cada campo que você esqueceu de tratar.\n\nÉ o lugar onde o TypeScript economiza mais tempo: o campo que às vezes vem nulo aparece como erro no editor, não como tela branca no celular de alguém.',
        codeSnippet:
            'interface Nota {\n  valor: number;\n  comentario?: string;\n}\n\nconst notas: Nota[] = await resposta.json();',
        xpReward: 16,
        coinReward: 8,
      ),
    ],
  ),
];
