---
description: Как локально разобрать выгруженный файл Figma (.fig) — контейнер, схемы, декодирование 777k узлов
---
---
name: decoding-figma-fig
description: Разбор выгруженного из Figma файла .fig без токена и без API — контейнер, извлечение схемы Kiwi, распаковка zstd, декодирование графа сцены в узлы с размерами, текстами и шрифтами. Загружать, когда есть файл .fig и нужны точные данные макета (геометрия, кегли, цвета, тексты) для сверки с вёрсткой.
---

# Разбор .fig локально

Проверено 14.09.2026 на файле 2,5 ГБ (выгрузка Figma Desktop). Никаких токенов и API не нужно:
`.fig` — это обычный zip, внутри которого лежит бинарный граф сцены.

## Что внутри

```
$ unzip -l "Файл.fig"
  canvas.fig     ~55 МБ   — граф сцены (то, что нужно)
  images/        1960 шт  — растровые ассеты
  videos/                 — видео
  meta.json               — имя файла, render_coordinates, дата выгрузки
  thumbnail.png
```

## Формат canvas.fig (важно, легко ошибиться)

```
[0..7]    "fig-kiwi"
[8..11]   uint32 версия формата (у нас 106)
[12..15]  uint32 длина deflate-блока
[16..]    deflate (raw, wbits=-15) → Kiwi БИНАРНАЯ СХЕМА
далее     4 байта uint32 — длина zstd-фрейма
далее     zstd-фрейм → kiwi-сообщение с nodeChanges
```

Ключевые грабли:

- **deflate лежит с нулевого смещения 16 и его надо распаковывать как raw deflate**: `zlib.decompressobj(-15)`.
- **схема начинается сразу с varint-числа определений** (у нас 643), а не с длины строки. Раньше я принял эти два байта за длину и час искал, почему схема «не влезает».
- **тело графа — не deflate, а zstd**, и он не декодируется с offset 29615: перед магией `28 b5 2f fd` лежит 4-байтная длина. Ищите магию поиском и берите смещение после неё, не угадывайте.
- **python-zstandard может отказаться** («Unknown frame descriptor»), если фрейм без content size; Node справляется: `zlib.zstdDecompressSync`. Важно скормить ВЕСЬ фрейм: на усечённых данных Node говорит «unexpected end of file».

Рабочие команды:

```bash
cd /tmp/fig && npm i kiwi-schema        # декодер схемы Kiwi

python3 - <<'PY'
import zlib, struct
raw = open('extracted/canvas.fig','rb').read()
ver, meta_len = struct.unpack_from('<II', raw, 8)
d = zlib.decompressobj(-15); meta = d.decompress(raw[16:16+meta_len]); meta += d.flush()
open('schema.bin','wb').write(meta)                      # это и есть бинарная схема Kiwi
off = raw.find(b'\x28\xb5\x2f\xfd', 16+meta_len)          # начало zstd-фрейма
print('schema', len(meta), 'zstd at', off, 'declared len', struct.unpack_from('<I', raw, off-4)[0])
open('scene.zst','wb').write(raw[off:])
PY

node -e "const z=require('zlib'),f=require('fs');const o=z.zstdDecompressSync(f.readFileSync('/tmp/fig/scene.zst'));f.writeFileSync('/tmp/fig/scene.bin',o);console.log(o.length)"
```

## Декодирование

```js
const fs = require('fs');
const { decodeBinarySchema, compileSchema } = require('kiwi-schema');
const schema = compileSchema(decodeBinarySchema(fs.readFileSync('schema.bin')));
const buf = fs.readFileSync('scene.bin');       // ~380 МБ
const msg = schema.decodeMessage(buf);          // ровно один аргумент!
console.log(msg.type, msg.nodeChanges.length);  // NODE_CHANGES, 777176
```

- `schema.decodeMessage(buffer)` — **один аргумент** и вызов именно через объект схемы (внутри `this.ByteBuffer`). Варианты `decode`, `decodeMessage(buf, bb, obj)` не работают — молча отдают пустой результат без ошибки, что хуже всего.
- Запускать с большим heap: `node --max-old-space-size=11000` (на машине 16 ГБ хватило).
- Сразу писать узлы в JSONL: граф в памяти не удержать, а `nodes.jsonl` вышел 530 МБ.

## Полезные поля узла (NodeChange)

`guid {sessionID, localID}`, `parentIndex.guid/position`, `type` (см. NodeType), `phase`, `name`,
`size {x,y}`, `transform {m00..m12}`, `textData.characters`, `fontSize`, `fontName.family/style`,
`lineHeight`, `letterSpacing`, `fillPaints[0].color {r,g,b,a}`, `stackSpacing`,
`stackVerticalPadding/stackHorizontalPadding`, `stackPadding`, `cornerRadius`, `visible`, `opacity`.

`NodeType`: 4 FRAME, 13 TEXT, 15 SYMBOL, 16 INSTANCE, 6 VECTOR, 2 CANVAS, 1 DOCUMENT.

## Что реально получается достать

- Полные фреймы страниц по брейкпоинтам: в файле есть `FRAME` с именами вида
  `Модуль 375/768/1440/1920`, `Решение 1440`, `Вопросы и ответы 1440`, `Desktop (1440)`,
  `Mobile (375)` — по ним считается высота макета для сверки с высотой живой страницы.
- Стили текста по совпадению строки: `figma_texts.json` (текст → fontSize/font/lineHeight) —
  по нему сверяются кегли живой страницы с макетом, если совпадение искать по самому тексту.
- Палитра: топ цветов по всем заливкам.

## Грабли интерпретации

- **Дети инстансов не лежат под инстансом** — они в мастер-компоненте. Обход поддерева инстанса
  даёт ноль текстов. Искать мастер по имени бесполезно (в файле десятки тысяч SYMBOL с именами
  вида `Size=M, Text=No, Informer=No, State=Default` — фильтр по «form» ловит `Informer` и `Format`).
- Поэтому «в макете есть подпись X» ≠ «подпись X относится к этому блоку». Проверять только по
  конкретной ноде из ссылки.
- Имена компонентов в макете и на статус-борде не совпадают. Связывать надо по **node-id**
  (`?node-id=8270-245103` → `sessionID:localID`).
- Файл `.fig` может содержать не только сайт: в выгрузке был и сам статус-борд, и разные варианты
  главной (`главная 1..10`), и другие макеты. Отбирать по имени фрейма и размеру.
