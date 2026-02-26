# install.ps1 - Install fah (Audio Hotkey Player) on Windows
# Works both locally (powershell -File install.ps1) and piped (irm ... | iex)

$ErrorActionPreference = "Stop"

$RepoUrl   = "https://github.com/manuvikash/Fah.git"
$ConfigDir = Join-Path $env:APPDATA "fah"

# ── Detect local vs piped execution ───────────────────────────────────────────
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "pyproject.toml"))) {
    $ProjectDir = $PSScriptRoot
} else {
    # Running via irm | iex - clone the repo
    $ProjectDir = Join-Path $env:LOCALAPPDATA "fah"
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Error: git is required. Install git and retry." -ForegroundColor Red
        exit 1
    }
    if (Test-Path (Join-Path $ProjectDir ".git")) {
        Write-Host "Updating fah..." -ForegroundColor Green
        git -C $ProjectDir pull --ff-only --quiet
    } else {
        if (Test-Path $ProjectDir) { Remove-Item -Recurse -Force $ProjectDir }
        Write-Host "Cloning fah into $ProjectDir..." -ForegroundColor Green
        git clone --depth 1 $RepoUrl $ProjectDir
    }
}

Set-Location $ProjectDir

# ── Find Python 3 ─────────────────────────────────────────────────────────────
$py = $null
foreach ($cmd in @("python", "python3", "py")) {
    try {
        $ver = & $cmd --version 2>&1
        if ($ver -match "Python 3") { $py = $cmd; break }
    } catch {}
}
if (-not $py) {
    Write-Host "Error: Python 3 not found. Install from https://python.org (tick 'Add to PATH')" -ForegroundColor Red
    exit 1
}
Write-Host "Found $( & $py --version 2>&1 )" -ForegroundColor Green

# ── Create virtual environment ─────────────────────────────────────────────────
if (-not (Test-Path ".venv")) {
    Write-Host "Creating virtual environment..." -ForegroundColor Green
    & $py -m venv .venv
}

# ── Install package into venv ──────────────────────────────────────────────────
Write-Host "Installing dependencies..." -ForegroundColor Green
& .\.venv\Scripts\pip.exe install --quiet -e .

# ── Set up config directory ────────────────────────────────────────────────────
if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir | Out-Null
}

$configFile = Join-Path $ConfigDir "config.yaml"
if (-not (Test-Path $configFile)) {
    Copy-Item "config.yaml" -Destination $configFile
    Write-Host "Config copied to $configFile" -ForegroundColor Green
} else {
    Write-Host "Config already exists at $configFile - skipping" -ForegroundColor Yellow
}

$mp3 = Join-Path $ConfigDir "fah.mp3"
if (-not (Test-Path $mp3)) {
    if (Test-Path "fah.mp3") {
        Copy-Item "fah.mp3" -Destination $mp3
        Write-Host "Audio file copied to $mp3" -ForegroundColor Green
    } else {
        Write-Host "Place your audio file at: $mp3" -ForegroundColor Yellow
    }
}

# ── Done ───────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Install complete!" -ForegroundColor Green
Write-Host "  Run:    $ProjectDir\start_windows.bat"
Write-Host "  Config: $configFile"
Write-Host "  Audio:  $mp3"
