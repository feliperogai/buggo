import '../../shared/models/lesson.dart';
import 'languages/backend_curricula.dart';
import 'languages/database_curricula.dart';
import 'languages/frontend_curricula.dart';
import 'languages/mobile_curricula.dart';
import 'languages/systems_curricula.dart';
import 'python_curriculum.dart';

/// Todos os níveis do app, de todas as linguagens, numa lista só.
///
/// A navegação (mapa do nível, tela de desafio) trabalha com o índice dentro
/// desta lista, então a **ordem tem que ser estável**: mudar a ordem não
/// perde progresso — ele é gravado por id de lição — mas troca o significado
/// de qualquer índice que estiver em trânsito.
///
/// Quem escolhe o que aparece é [levelsForLanguage]: cada nível carrega o
/// `languageId` da sua trilha. Nenhuma trilha depende de outra — quem quiser
/// começar por Rust em vez de lógica, começa por Rust.
const List<CourseLevel> courseCurriculum = [
  // Lógica (2 níveis) + Python (4 níveis) — as duas trilhas mais longas,
  // que existem desde a primeira versão do app.
  ...pythonCurriculum,
  ...javascriptCurriculum,
  ...typescriptCurriculum,
  ...javaCurriculum,
  ...csharpCurriculum,
  ...cppCurriculum,
  ...cCurriculum,
  ...goCurriculum,
  ...kotlinCurriculum,
  ...swiftCurriculum,
  ...phpCurriculum,
  ...rubyCurriculum,
  ...rustCurriculum,
  ...dartCurriculum,
  ...queriesCurriculum,
];

/// Um nível junto do índice que ele ocupa em [courseCurriculum] — é esse
/// índice que as rotas carregam.
class IndexedLevel {
  final int index;
  final CourseLevel level;

  const IndexedLevel(this.index, this.level);
}

/// Níveis da trilha de [languageId], na ordem, já com o índice global.
List<IndexedLevel> levelsForLanguage(String languageId) {
  final result = <IndexedLevel>[];
  for (var i = 0; i < courseCurriculum.length; i++) {
    if (courseCurriculum[i].languageId == languageId) {
      result.add(IndexedLevel(i, courseCurriculum[i]));
    }
  }
  return result;
}

/// Todas as lições de uma linguagem, para contar progresso da trilha.
List<Lesson> lessonsForLanguage(String languageId) => courseCurriculum
    .where((level) => level.languageId == languageId)
    .expand((level) => level.lessons)
    .toList(growable: false);

/// Se a linguagem tem conteúdo. Uma opção listada sem nível nenhum apareceria
/// como trilha vazia, então é isto que decide o "Em breve".
bool hasCurriculum(String languageId) =>
    courseCurriculum.any((level) => level.languageId == languageId);

/// Quantas lições o app inteiro tem, somando todas as linguagens.
int get totalLessonCount =>
    courseCurriculum.fold(0, (sum, level) => sum + level.lessons.length);
