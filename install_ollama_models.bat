@echo off
rem Install models for local Obsidian assistant: nomic-embed-text and qwen2.5:7b
rem Run by double click. Ollama must be installed: https://ollama.com/download
setlocal
set EMBED_MODEL=nomic-embed-text
set CHAT_MODEL=qwen2.5:7b

where ollama >nul 2>nul
if errorlevel 1 (
  echo Ollama not found. Install it from https://ollama.com/download and run again.
  pause
  exit /b 1
)

echo Pulling embedding model %EMBED_MODEL% (about 270 MB)
ollama pull %EMBED_MODEL%
if errorlevel 1 goto fail

echo Pulling chat model %CHAT_MODEL% (about 4.7 GB, 6-8 GB free memory needed)
ollama pull %CHAT_MODEL%
if errorlevel 1 goto fail

echo.
echo Done. Installed models:
ollama list
echo Next: Obsidian - Smart Connections plugin - endpoint http://127.0.0.1:11434
pause
exit /b 0

:fail
echo Download failed. Check that Ollama is running and internet is available for the first download.
pause
exit /b 1
