# LC4 Optimization & Feature Plan

## Оптимизация 1: Убрать RwLock contention

**Файл:** `src/scan/mod.zig`

**Проблема:** Каждый walker делает `rwlock.lockUncancelable()` на каждое добавление файла (строка 196-200). При 50+ поддиректориях — серьёзный contention.

**Решение:**
- Заменить `ScanContext` (с shared `entries` + `rwlock`) на `SubdirTask`
- Каждый walker получает свой `SubdirTask` с локальным `entries: ArrayList(FileEntry)`
- Walker пишет в `task.entries` без блокировок
- После `group.await()` — мержим все `task.entries` в один `result` list
- Убираем `rwlock` полностью

**Новая структура:**
```zig
const SubdirTask = struct {
    entries: std.ArrayList(FileEntry),
    allocator: std.mem.Allocator,
    respect_gitignore: bool,
    gitignore_patterns: ?[]const gitignore.Pattern,
    extensions: ?[]const []const u8,
    scan_all: bool,
};
```

## Оптимизация 2: Один проход подсчёта строк

**Файл:** `src/count/lines.zig`

**Проблема:** На каждую строку — `findScalar('\n')`, `trimStart`, `startsWith` для комментария, `find` для блока = 3-4 прохода по байтам.

**Решение:** Один проход по байтам — ищем `\n`, `//`, `/*`, `*/` одновременно. Состояние: `in_block_comment: bool`. Считаем `\n`, при遇到 `//` пропускаем до конца строки, при遇到 `/*` включаем block mode.

## Оптимизация 3: HashMap для языков

**Файл:** `src/lang/mod.zig`

**Проблема:** Линейный поиск по 77 расширениям (строка 110-112).

**Решение:** `StringHashMap(*const Language)` из расширения в язык. O(1) вместо O(n).

## Фича 4: Путь аргументом

**Файлы:** `cli.zig` + `scan/mod.zig` + `config.zig`

**Решение:** Позиционный аргумент = корень сканирования. `lc4 ./src` или `lc4 C:\project`. Если нет аргумента — CWD (как сейчас).

## Фича 5: --version

**Файл:** `cli.zig`

**Решение:** Одна строка: вывести версию и выйти.

## Фича 6: --no-color

**Файлы:** `cli.zig` + `config.zig` + `colors.zig`

**Решение:** Флаг в Config. Если true — все цвета = пустые строки.

## Фича 7: --sort

**Файлы:** `cli.zig` + `config.zig` + `count/mod.zig`

**Решение:** `--sort lines|files|code|name`. Default: `lines`. Меняем компаратор в `aggregate`.
