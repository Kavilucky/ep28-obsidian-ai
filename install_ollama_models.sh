#!/usr/bin/env bash
# Установка моделей для локального ассистента Obsidian (Ollama + nomic-embed-text + qwen2.5:7b).
# Запуск: bash install_ollama_models.sh
set -euo pipefail

EMBED_MODEL="nomic-embed-text"
CHAT_MODEL="qwen2.5:7b"

if ! command -v ollama >/dev/null 2>&1; then
  echo "Ollama не найдена. Установите с https://ollama.com/download и запустите скрипт снова."
  exit 1
fi

# Сервер должен слушать только локальный адрес (по умолчанию так и есть).
if ! curl -fsS http://127.0.0.1:11434/api/version >/dev/null 2>&1; then
  echo "Сервер Ollama не отвечает на 127.0.0.1:11434. Запустите 'ollama serve' в другом окне."
  exit 1
fi

echo "Скачиваю модель эмбеддингов: ${EMBED_MODEL} (около 270 МБ)"
ollama pull "${EMBED_MODEL}"

echo "Скачиваю чат-модель: ${CHAT_MODEL} (около 4,7 ГБ, нужна свободная память 6-8 ГБ)"
ollama pull "${CHAT_MODEL}"

echo
echo "Готово. Установленные модели:"
ollama list
echo "Дальше: Obsidian -> плагин Smart Connections -> endpoint http://127.0.0.1:11434"
