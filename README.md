# Веб-компоненты дипломного проекта

## Структура проекта

### `api/`
Бэкенд на FastAPI для:
- Конвертации текста в фонемы
- Обработки аудио
- Работы с моделями

### `phoneme_visualizer/`
Веб-приложение на Flutter для:
- Визуализации фонем
- Конвертации текста в ARPABET

### `vad_wasm/`
WebAssembly реализация VAD:
- VAD алгоритм на Rust
- JavaScript интерфейс
- Обработка аудио в реальном времени

### `vad_plugin/`
Flutter плагин для VAD:
- Интерфейс для работы с VAD
- Обработка аудиопотока
- Интеграция с WebAssembly

## Getting Started

Each component has its own setup instructions and dependencies. Please refer to the README files in individual directories for specific setup and usage instructions. 