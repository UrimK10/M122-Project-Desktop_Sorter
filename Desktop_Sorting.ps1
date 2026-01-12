# -----------------------------------------
# Desktop Assistant – Easy / Pro Mode
# -----------------------------------------

# ===============================
# BASIS KONFIGURATION
# ===============================
$desktop = "$env:USERPROFILE\OneDrive - TBZ\Desktop"
$logBase = "C:\DesktopSorterLogs"

# ===============================
# API KONFIGURATION
# ===============================
$APINinjasKey = "6++L9ketghqptNOHr/GrsA==gwbVGlYzQ1z66rxJ"

# ===============================
# EASY MODE KATEGORIEN
# ===============================
$EasyCategories = @{
    "Bilder"     = @(".png", ".jpg", ".jpeg", ".gif", ".bmp")
    "Videos"     = @(".mp4", ".mkv", ".avi", ".mov")
    "Dokumente"  = @(".txt", ".pdf", ".docx", ".xlsx")
    "Audio"      = @(".mp3", ".wav", ".flac")
    "Programme"  = @(".exe", ".msi")
    "Shortcuts"  = @(".lnk")
}

# ===============================
# LOGGING (PRO AKTION)
# ===============================
function Start-NewLog {
    $script:logStartTime = Get-Date
    $dateFolder = $logStartTime.ToString("yyyy-MM-dd")
    $timeFile   = $logStartTime.ToString("HH-mm-ss") + ".txt"

    $script:logDir  = Join-Path $logBase $dateFolder
    $script:logFile = Join-Path $logDir $timeFile

    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }
}

function Write-Log {
    param([string]$Message)
    Add-Content $script:logFile "$(Get-Date -Format HH:mm:ss) $Message"
}

function Read-LogSummary {
    if (-not (Test-Path $script:logFile)) { return }
    $moves = Get-Content $script:logFile | Where-Object {
        $_ -match "\[MOVE\]"
    }
    Write-Host "`n[READ] Verschobene Dateien: $($moves.Count)"
}

# ===============================
# WEISHEIT DES TAGES
# ===============================
function Show-QuoteOfTheDay {
    Write-Host "`nWeisheit des Tages:`n"
    try {
        $headers = @{ "X-Api-Key" = $APINinjasKey }
        $response = Invoke-RestMethod `
            -Uri "https://api.api-ninjas.com/v1/quotes" `
            -Headers $headers
        if ($response.Count -gt 0) {
            $quote = "`"$($response[0].quote)`" — $($response[0].author)"
            Write-Host $quote
            Write-Log "[QUOTE] $quote"
        }
    } catch {
        Write-Log "[ERROR] API Fehler"
    }
}

# ===============================
# EASY MODE
# ===============================
function Sort-EasyMode {
    param($Desktop, $Categories)

    Start-NewLog
    Write-Log "[INFO] Easy Mode gestartet"
    Write-Host "`nEasy Mode gestartet"

    foreach ($cat in $Categories.Keys) {
        $path = Join-Path $Desktop $cat
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path | Out-Null
            Write-Log "[INFO] Ordner erstellt: $cat"
        }
    }

    foreach ($file in Get-ChildItem $Desktop -File) {
        foreach ($category in $Categories.Keys) {
            if ($Categories[$category] -contains $file.Extension.ToLower()) {
                Move-Item $file.FullName -Destination (Join-Path $Desktop $category) -Force
                Write-Host "$($file.Name) -> $category"
                Write-Log "[MOVE] $($file.Name) -> $category"
                break
            }
        }
    }

    Read-LogSummary
    Show-QuoteOfTheDay
}

# ===============================
# PRO MODE
# ===============================
function Sort-ProMode {
    param($Desktop)

    Start-NewLog
    Write-Log "[INFO] Pro Mode gestartet"
    Write-Host "`nPro Mode gestartet"

    $extensions = (Read-Host "Dateiendungen (.png,.jpg)").Split(",") |
        ForEach-Object { $_.Trim().ToLower() }

    $folders = Get-ChildItem $Desktop -Directory

    Write-Host "`nZielordner wählen:"
    for ($i = 0; $i -lt $folders.Count; $i++) {
        Write-Host "$($i+1)) $($folders[$i].Name)"
    }
    Write-Host "0) Neuen Ordner erstellen"

    $choice = Read-Host "Nummer wählen"

    if ($choice -eq "0") {
        $name = Read-Host "Name des neuen Ordners"
        $targetFolder = Join-Path $Desktop $name
        New-Item -ItemType Directory -Path $targetFolder | Out-Null
        Write-Log "[INFO] Neuer Ordner erstellt: $name"
    }
    elseif ($choice -ge 1 -and $choice -le $folders.Count) {
        $targetFolder = $folders[$choice - 1].FullName
    }
    else { return }

    Get-ChildItem $Desktop -File | Where-Object {
        $extensions -contains $_.Extension.ToLower()
    } | ForEach-Object {
        Move-Item $_.FullName -Destination $targetFolder -Force
        Write-Log "[MOVE] $($_.Name) -> $(Split-Path $targetFolder -Leaf)"
    }

    Read-LogSummary
    Show-QuoteOfTheDay
}

# ===============================
# AUTO DELETE (ERWEITERT)
# ===============================
function Auto-Delete {

    Start-NewLog
    Write-Log "[INFO] Auto-Delete gestartet"

    $folder = Read-Host "Ordnerpfad"
    if (-not (Test-Path $folder)) { return }

    $unit  = Read-Host "Einheit (m/h/d)"
    if ($unit -notin @("m","h","d")) { return }

    $value = Read-Host "Alter (Zahl)"
    if (-not ($value -as [int]) -or $value -le 0) { return }

    switch ($unit) {
        "m" { $cutoff = (Get-Date).AddMinutes(-$value) }
        "h" { $cutoff = (Get-Date).AddHours(-$value) }
        "d" { $cutoff = (Get-Date).AddDays(-$value) }
    }

    $files = Get-ChildItem $folder -File | Where-Object {
        $_.LastWriteTime -lt $cutoff
    }

    if ($files.Count -eq 0) {
        Write-Host "Keine Dateien gefunden"
        return
    }

    Write-Host "`nFolgende Dateien werden gelöscht:`n"
    $files | ForEach-Object { Write-Host $_.Name }

    if ((Read-Host "`nWirklich löschen? (y/n)").ToLower() -ne "y") {
        Write-Log "[INFO] Auto-Delete abgebrochen"
        return
    }

    foreach ($file in $files) {
        Remove-Item $file.FullName -Force
        Write-Log "[DELETE] $($file.Name)"
    }

    Write-Host "`nEs wurden $($files.Count) Dateien gelöscht."
    Write-Log "[INFO] $($files.Count) Dateien gelöscht"
}

# ===============================
# SYSTEMINFOS
# ===============================
function Show-SystemInfo {

    Start-NewLog
    Write-Log "[INFO] Systeminfos angezeigt"

    Write-Host "`nSysteminformationen:`n"
    Write-Host "CPU : $((Get-CimInstance Win32_Processor)[0].Name)"
    Write-Host "RAM : $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB,2)) GB"
    Write-Host "GPU : $((Get-CimInstance Win32_VideoController)[0].Name)"
    Write-Host "OS  : $((Get-CimInstance Win32_OperatingSystem).Caption)"
}

# ===============================
# HAUPTMENÜ
# ===============================
$exitProgram = $false

do {
    Clear-Host
    Write-Host "DESKTOP ASSISTANT v1.0"

    Write-Host "1) Desktop sortieren"
    Write-Host "2) Alte Dateien automatisch löschen"
    Write-Host "3) Systeminformationen anzeigen"
    Write-Host "0) Beenden"

    $choice = Read-Host "Bitte wählen"

    switch ($choice) {
        "1" {
            if ((Read-Host "Easy oder Pro?").ToLower() -eq "easy") {
                Sort-EasyMode -Desktop $desktop -Categories $EasyCategories
            } else {
                Sort-ProMode -Desktop $desktop
            }
        }
        "2" { Auto-Delete }
        "3" { Show-SystemInfo }
        "0" { $exitProgram = $true }
    }

    if (-not $exitProgram) {
        Write-Host "`nENTER drücken..."
        Read-Host
    }

} while (-not $exitProgram)
