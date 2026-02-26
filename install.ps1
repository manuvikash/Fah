# install.ps1 — one-line installer for fah (Audio Hotkey Player)
# Usage: irm https://raw.githubusercontent.com/manuvikash/Fah/main/install.ps1 | iex

$ErrorActionPreference = "Continue"

$REPO     = "https://github.com/manuvikash/Fah"
$RAW      = "https://raw.githubusercontent.com/manuvikash/Fah/main"
$CONFIG   = Join-Path $env:APPDATA "fah"

function Info  { param($msg) Write-Host "[fah] $msg" -ForegroundColor Green }
function Warn  { param($msg) Write-Host "[fah] $msg" -ForegroundColor Yellow }
function Fatal { param($msg) Write-Host "[fah] ERROR: $msg" -ForegroundColor Red; exit 1 }

# ── Python ────────────────────────────────────────────────────────────────────
Info "Checking for Python 3..."
$py = $null
foreach ($cmd in @("python", "python3", "py")) {
    try {
        $ver = & $cmd --version 2>&1
        if ($ver -match "Python 3") { $py = $cmd; break }
    } catch {}
}
if (-not $py) {
    Fatal "Python 3 not found. Install it from https://python.org (tick 'Add to PATH') then re-run."
}
Info "Found: $( & $py --version 2>&1 )"

# ── pipx ─────────────────────────────────────────────────────────────────────
Info "Checking for pipx..."
if (-not (Get-Command pipx -ErrorAction SilentlyContinue)) {
    Info "Installing pipx..."
    & $py -m pip install --user pipx
}

# Invoke pipx via python -m to avoid PATH issues with user-installed scripts
function Pipx { & $py -m pipx @args }
Info "pipx ready: $( Pipx --version )"

# ── Install / upgrade fah ─────────────────────────────────────────────────────
$installed = (Pipx list 2>&1) | Select-String "package fah"
if ($installed) {
    Info "Upgrading fah..."
    Pipx upgrade fah
} else {
    Info "Installing fah via pipx..."
    Pipx install "git+$REPO.git"
}

# ── Config directory ──────────────────────────────────────────────────────────
if (-not (Test-Path $CONFIG)) { New-Item -ItemType Directory -Path $CONFIG | Out-Null }

$configYaml = Join-Path $CONFIG "config.yaml"
if (-not (Test-Path $configYaml)) {
    Info "Downloading config.yaml -> $configYaml"
    Invoke-WebRequest "$RAW/config.yaml" -OutFile $configYaml
} else {
    Warn "config.yaml already exists — skipping (edit it at $configYaml)"
}

$mp3 = Join-Path $CONFIG "fah.mp3"
if (-not (Test-Path $mp3)) {
    Info "Downloading fah.mp3 -> $mp3"
    Invoke-WebRequest "$RAW/fah.mp3" -OutFile $mp3
} else {
    Warn "fah.mp3 already exists — skipping"
}

# ── Autostart (Registry Run key) ─────────────────────────────────────────────
$fahCmd = Get-Command fah -ErrorAction SilentlyContinue
$fahBin = if ($fahCmd) { $fahCmd.Source } else { Join-Path $env:USERPROFILE ".local\bin\fah.exe" }

$choice = Read-Host "`nSet up fah to start automatically on login? [y/N]"
if ($choice -match "^[Yy]$") {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $regPath -Name "fah" -Value "`"$fahBin`""
    Info "Autostart enabled (registry Run key)"
} else {
    Info "Skipping autostart."
}

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "fah installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "  Run now:     fah"
Write-Host "  Edit config: $configYaml"
Write-Host "  Audio file:  $mp3"
Write-Host ""
Warn "If 'fah' is not found, restart your terminal or open a new PowerShell window."
