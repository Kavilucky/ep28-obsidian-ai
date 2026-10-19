#!/usr/bin/env bash
# Зашифрованный бэкап хранилища Obsidian и индекса .smart-env по схеме 3-2-1.
# 3 копии: рабочее хранилище + локальный архив + копия на внешнем диске; 2 носителя; 1 внешний.
# Запуск: VAULT="$HOME/Obsidian/MyVault" LOCAL_DIR="$HOME/backups/obsidian" EXTERNAL_DIR="/mnt/usb/obsidian" bash backup_vault.sh
# Пароль спрашивает gpg, в скрипте он не хранится.
set -euo pipefail

VAULT="${VAULT:?Укажите путь к хранилищу: VAULT=/путь/к/хранилищу}"
LOCAL_DIR="${LOCAL_DIR:-$HOME/backups/obsidian}"
EXTERNAL_DIR="${EXTERNAL_DIR:?Укажите внешний диск: EXTERNAL_DIR=/mnt/usb/obsidian}"
KEEP="${KEEP:-14}"

command -v gpg >/dev/null 2>&1 || { echo "Нужен gpg для шифрования. Установите gnupg."; exit 1; }
[ -d "$VAULT" ] || { echo "Хранилище не найдено: $VAULT"; exit 1; }
[ -d "$EXTERNAL_DIR" ] || { echo "Внешний диск не подключён: $EXTERNAL_DIR"; exit 1; }
mkdir -p "$LOCAL_DIR"

STAMP="$(date +%Y%m%d_%H%M%S)"
ARCHIVE="$LOCAL_DIR/vault_${STAMP}.tar.gz.gpg"

# В архив входят заметки и индекс .smart-env; кэш корзины пропускается.
tar -C "$(dirname "$VAULT")" --exclude=".trash" -czf - "$(basename "$VAULT")" \
  | gpg --symmetric --cipher-algo AES256 --output "$ARCHIVE"

cp "$ARCHIVE" "$EXTERNAL_DIR/"
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
cp "$ARCHIVE.sha256" "$EXTERNAL_DIR/"

# Сверка копии на внешнем диске.
( cd "$EXTERNAL_DIR" && sha256sum -c "$(basename "$ARCHIVE").sha256" )

# Ротация: оставить последние KEEP архивов в обеих папках.
for dir in "$LOCAL_DIR" "$EXTERNAL_DIR"; do
  ls -1t "$dir"/vault_*.tar.gz.gpg 2>/dev/null | tail -n +$((KEEP + 1)) | while read -r old; do
    rm -f "$old" "$old.sha256"
  done
done

echo "Готово: $ARCHIVE и копия в $EXTERNAL_DIR"
echo "Проверьте восстановление: gpg --decrypt <архив> | tar -tz | head"
echo "Не удаляйте оригиналы, пока копия не проверена."
