# agent-skills

Набор скиллов для агентов Letta. Каждый скилл — папка с `SKILL.md` внутри `skills/`.
Проверено на Letta Code 0.32.1.

## Что внутри

### `ocr-images` — распознавание текста с картинок и сканов
Три движка с разными ролями: нативный **macOS Vision** через Swift (быстро, бесплатно, 1.8 сек на кадр),
**tesseract** и **vision-модель** как второе мнение (на тесте дала на 27% больше текста там, где OCR врал).
Внутри — готовый Swift-скрипт, правила чистки служебных надписей интерфейса и разбор грабель:
какие фильтры съедают настоящий текст.

Особенно полезно, когда документ состоит из картинок: например `.docx` с 51 скриншотом и нулём символов текста.

### `decoding-figma-fig` — разбор выгрузки Figma без токена
Файл `.fig` — это zip: внутри схема Kiwi, zstd-блок с графом сцены и ассеты. Скилл описывает формат,
смещения, сборку декодера на `kiwi-schema` и грабли интерпретации. На реальном файле —
777 176 узлов с размерами, текстами, шрифтами и цветами.

### `dispatching-cursor` — Cursor CLI как headless-субагент
`cursor-agent` как stateless исполнитель на подписке Cursor: флаги, режимы, `--trust`,
поведение при региональных ограничениях.

## Установка

Через интерфейс: **Import from GitHub** → URL папки скилла.

Из терминала:

```bash
letta install https://github.com/carlsonchik/agent-skills/tree/main/skills/ocr-images
letta install https://github.com/carlsonchik/agent-skills/tree/main/skills/decoding-figma-fig
letta install https://github.com/carlsonchik/agent-skills/tree/main/skills/dispatching-cursor
```

Скиллы читаются агентом по требованию: описание попадает в контекст, тело подгружается, когда нужно.

## English

Portable Letta skills: OCR from images and scans (native macOS Vision + fallbacks),
parsing exported Figma `.fig` files without an API token, and running the Cursor CLI as a
headless subagent. Install any folder with `letta install <github-tree-url>`.
