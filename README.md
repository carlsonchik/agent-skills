# agent-skills

Скиллы для агентов Letta, связанные с извлечением и восстановлением текста.
Каждый скилл — папка с `SKILL.md` внутри `skills/`. Проверено на Letta Code 0.32.1.

## `ocr-images` — восстановление текста из картинок и сканов

Работает, когда текста в файле нет, а есть только изображения: сканы, скриншоты, документы,
состоящие из картинок целиком (например `.docx` с 51 скриншотом и нулём символов текста).

Три движка с разными ролями:

| Движок | Когда | Скорость |
|---|---|---|
| **macOS Vision** (готовый Swift-скрипт внутри скилла) | основной проход по печатному тексту | 1.8 сек на кадр, бесплатно |
| **vision-модель** | сложные кадры: окна программ, рукописное, стилизованное | на тесте дала **на 27% больше текста** |
| **tesseract** | почти никогда | на тёмных скриншотах вернул 0 строк |

Внутри — не только распознавание, но и обязательный **этап чистки**: как убрать служебные надписи
интерфейса, и разбор четырёх грабель, на которых фильтры съедают настоящий текст (например правило
«строки короче 6 символов — мусор» убивает слайд с единственным словом «Либидо»).

## `dispatching-cursor` — Cursor CLI как headless-субагент

`cursor-agent` как stateless исполнитель на подписке Cursor: флаги, режимы, `--trust`,
поведение при региональных ограничениях.

## Установка

Через интерфейс: **Import from GitHub** → URL папки скилла.

Из терминала:

```bash
letta install https://github.com/carlsonchik/agent-skills/tree/main/skills/ocr-images
letta install https://github.com/carlsonchik/agent-skills/tree/main/skills/dispatching-cursor
```

## English

Letta skills for extracting text from images and scans (native macOS Vision plus fallbacks, with a
mandatory cleanup stage), and for running the Cursor CLI as a headless subagent.

Website-testing skills live in a separate private repository.
