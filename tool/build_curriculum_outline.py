#!/usr/bin/env python3
"""Gera `server/lib/curriculum-outline.ts` a partir das trilhas em Dart.

O servidor precisa saber o que cada linguagem ensina e em que ordem, por dois
motivos: descobrir sozinho até onde a pessoa foi (a partir de
`completed_lessons`, que ele já tem no banco) e montar o prompt do desafio do
dia só com assunto que ela já viu.

Duplicar o conteúdo inteiro no servidor seria pedir divergência. O que sai
daqui é só o esqueleto — id e título de cada lição, título e descrição de cada
nível —, gerado do mesmo arquivo que o app usa.

Rode depois de mexer em qualquer trilha:

    python3 tool/build_curriculum_outline.py

O arquivo gerado é commitado: a Vercel não roda Python no build.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / 'lib' / 'data' / 'content'
OUTPUT = ROOT / 'server' / 'lib' / 'curriculum-outline.ts'

# A ordem tem que ser a mesma de `courseCurriculum` em curriculum.dart.
SOURCES = [
    CONTENT / 'python_curriculum.dart',
    CONTENT / 'languages' / 'frontend_curricula.dart',
    CONTENT / 'languages' / 'backend_curricula.dart',
    CONTENT / 'languages' / 'systems_curricula.dart',
    CONTENT / 'languages' / 'mobile_curricula.dart',
    CONTENT / 'languages' / 'database_curricula.dart',
]

LEVEL_START = re.compile(r'^  CourseLevel\($')
# Campos do nível ficam a 4 espaços; os da lição, a 8. É isso que separa os dois.
LEVEL_FIELD = re.compile(r"^    (\w+): '((?:[^'\\]|\\.)*)',?$")
LESSON_ID = re.compile(r"^        id: '([^']+)',$")
LESSON_TITLE = re.compile(r"^        title: '((?:[^'\\]|\\.)*)',$")


def unescape(value: str) -> str:
    return value.replace("\\'", "'").replace('\\\\', '\\')


def parse(path: pathlib.Path) -> list[dict]:
    levels: list[dict] = []
    current: dict | None = None
    pending_id: str | None = None

    for line in path.read_text(encoding='utf-8').splitlines():
        if LEVEL_START.match(line):
            current = {'languageId': None, 'title': None, 'description': None,
                       'lessons': []}
            levels.append(current)
            pending_id = None
            continue
        if current is None:
            continue

        field = LEVEL_FIELD.match(line)
        if field:
            name, value = field.group(1), unescape(field.group(2))
            if name in ('languageId', 'title', 'description'):
                current[name] = value
            continue

        lesson_id = LESSON_ID.match(line)
        if lesson_id:
            pending_id = lesson_id.group(1)
            continue

        lesson_title = LESSON_TITLE.match(line)
        if lesson_title and pending_id is not None:
            current['lessons'].append(
                {'id': pending_id, 'title': unescape(lesson_title.group(1))})
            pending_id = None

    return levels


def main() -> int:
    levels: list[dict] = []
    for source in SOURCES:
        if not source.exists():
            print(f'faltando: {source}', file=sys.stderr)
            return 1
        levels.extend(parse(source))

    problems = []
    seen_ids: set[str] = set()
    per_language: dict[str, int] = {}

    for level in levels:
        if not level['languageId'] or not level['title']:
            problems.append(f'nível sem languageId/title: {level}')
            continue
        if not level['lessons']:
            problems.append(f"nível sem lições: {level['title']}")
        level['index'] = per_language.get(level['languageId'], 0)
        per_language[level['languageId']] = level['index'] + 1
        for lesson in level['lessons']:
            if lesson['id'] in seen_ids:
                problems.append(f"id repetido: {lesson['id']}")
            seen_ids.add(lesson['id'])

    if problems:
        print('\n'.join(problems), file=sys.stderr)
        return 1

    body = ',\n'.join(
        '  ' + json.dumps({
            'languageId': level['languageId'],
            'index': level['index'],
            'title': level['title'],
            'description': level['description'] or '',
            'lessons': level['lessons'],
        }, ensure_ascii=False)
        for level in levels
    )

    OUTPUT.write_text(
        '// GERADO POR tool/build_curriculum_outline.py — NÃO EDITE À MÃO.\n'
        '//\n'
        '// Esqueleto das trilhas do app: o servidor usa isto para saber até\n'
        '// onde a pessoa chegou e para montar o prompt do desafio do dia só\n'
        '// com assunto que ela já viu. O conteúdo das lições continua só no\n'
        '// app; aqui ficam id e título.\n'
        '//\n'
        '// Regenere depois de mexer em qualquer trilha.\n\n'
        'export interface OutlineLesson {\n'
        '  id: string;\n'
        '  title: string;\n'
        '}\n\n'
        'export interface OutlineLevel {\n'
        '  languageId: string;\n'
        '  /** Posição do nível dentro da trilha da própria linguagem. */\n'
        '  index: number;\n'
        '  title: string;\n'
        '  description: string;\n'
        '  lessons: OutlineLesson[];\n'
        '}\n\n'
        'export const CURRICULUM_OUTLINE: OutlineLevel[] = [\n'
        f'{body},\n'
        '];\n',
        encoding='utf-8',
    )

    print(f'{len(levels)} níveis, {len(seen_ids)} lições, '
          f'{len(per_language)} linguagens -> {OUTPUT.relative_to(ROOT)}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
