# Encrypted backup of Obsidian vault and .smart-env index, 3-2-1 scheme.
# 3 copies: working vault + local archive + copy on external drive; 2 media; 1 external.
# Usage: powershell -ExecutionPolicy Bypass -File backup_vault.ps1 -Vault "D:\Notes" -External "E:\obsidian"
# Encryption uses gpg (Gpg4win). The passphrase is asked by gpg, it is never stored here.
param(
  [Parameter(Mandatory = $true)][string]$Vault,
  [Parameter(Mandatory = $true)][string]$External,
  [string]$LocalDir = (Join-Path $env:USERPROFILE "backups\obsidian"),
  [int]$Keep = 14
)
$ErrorActionPreference = "Stop"

if (-not (Get-Command gpg -ErrorAction SilentlyContinue)) { throw "gpg not found. Install Gpg4win first." }
if (-not (Test-Path $Vault)) { throw "Vault not found: $Vault" }
if (-not (Test-Path $External)) { throw "External drive not connected: $External" }
New-Item -ItemType Directory -Force -Path $LocalDir | Out-Null

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$tar = Join-Path $LocalDir "vault_$stamp.tar.gz"
$enc = "$tar.gpg"

# tar.exe ships with Windows 10+. The .trash folder is skipped, .smart-env is included.
$parent = Split-Path $Vault -Parent
$name = Split-Path $Vault -Leaf
tar -C $parent --exclude=".trash" -czf $tar $name
if ($LASTEXITCODE -ne 0) { throw "tar failed" }

gpg --symmetric --cipher-algo AES256 --output $enc $tar
if ($LASTEXITCODE -ne 0) { Remove-Item $tar -Force; throw "gpg failed" }
Remove-Item $tar -Force   # plain archive must not stay on disk

Copy-Item $enc $External
$hash = (Get-FileHash $enc -Algorithm SHA256).Hash
Set-Content -Path "$enc.sha256" -Value $hash
Copy-Item "$enc.sha256" $External

$copyHash = (Get-FileHash (Join-Path $External (Split-Path $enc -Leaf)) -Algorithm SHA256).Hash
if ($copyHash -ne $hash) { throw "Copy on external drive does not match" }

foreach ($dir in @($LocalDir, $External)) {
  Get-ChildItem $dir -Filter "vault_*.tar.gz.gpg" | Sort-Object LastWriteTime -Descending |
    Select-Object -Skip $Keep | ForEach-Object {
      Remove-Item $_.FullName -Force
      Remove-Item "$($_.FullName).sha256" -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Done: $enc and copy in $External"
Write-Host "Test restore on another machine. Do not delete originals until the copy is verified."
