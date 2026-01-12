# -----------------------------------------
# Desktop Assistant – Easy / Pro Mode
# -----------------------------------------

# -------------------------------
# BASIS KONFIGURATION
# -------------------------------
$desktop = "$env:USERPROFILE\OneDrive - TBZ\Desktop"
$logBase = "C:\DesktopSorterLogs"

# -------------------------------
# API KONFIGURATION
# -------------------------------
$APINinjasKey = "6++L9ketghqptNOHr/GrsA==gwbVGlYzQ1z66rxJ"

# -------------------------------
# EASY MODE KATEGORIEN
# -------------------------------
$EasyCategories = @{
    "Bilder"     = @(".png", ".jpg", ".jpeg", ".gif", ".bmp")
    "Videos"     = @(".mp4", ".mkv", ".avi", ".mov")
    "Dokumente"  = @(".txt", ".pdf", ".docx", ".xlsx")
    "Audio"      = @(".mp3", ".wav", ".flac")
    "Programme"  = @(".exe", ".msi")
}

# =====================================================
# FUNKTIONEN
# =====================================================

# -------------------------------
# LOGGING
# -------------------------------
function Write-Log {
    param([string]$Message)

    $dateFolder = Get-Date -Format "yyyy-MM-dd"
    $logDir = Join-Path $logBase $dateFolder

    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }

    $logFile = Join-Path $logDir "DesktopAssistant.log"
    Add-Content $logFile "$(Get-Date -Format HH:mm:ss) - $Message"
}

function Read-LogSummary {
    $dateFolder = Get-Date -Format "yyyy-MM-dd"
    $logFile = Join-Path (Join-Path $logBase $dateFolder) "DesktopAssistant.log"

    if (-not (Test-Path $logFile)) {
        Write-Host "Kein Logfile für heute gefunden."
        return
    }

    $count = (Select-String -Path $logFile -Pattern "->").Count
    Write-Host "`n[READ] Verschobene Dateien laut Log: $count"
}

# -------------------------------
# WEISHEIT DES TAGES
# -------------------------------
function Show-QuoteOfTheDay {

    Write-Host "`nWeisheit des Tages:`n"

    if ([string]::IsNullOrWhiteSpace($APINinjasKey)) {
        Write-Host "API Key fehlt"
        Write-Log "API Ninjas Key fehlt"
        return
    }

    try {
        $headers = @{ "X-Api-Key" = $APINinjasKey }

        $response = Invoke-RestMethod `
            -Uri "https://api.api-ninjas.com/v1/quotes" `
            -Method Get `
            -Headers $headers

        if ($response.Count -gt 0) {
            $quote = "`"$($response[0].quote)`" — $($response[0].author)"
            Write-Host $quote
            Write-Log "Weisheit des Tages: $quote"
        }
    }
    catch {
        Write-Host "Keine Weisheit verfügbar (API Fehler)"
        Write-Log "API Fehler: $_"
    }
}

# -------------------------------
# EASY MODE
# -------------------------------
function Sort-EasyMode {
    param($Desktop, $Categories)

    Write-Host "`nEasy Mode gestartet"
    Write-Log "Easy Mode gestartet"

    foreach ($cat in $Categories.Keys) {
        $path = Join-Path $Desktop $cat
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path | Out-Null
            Write-Log "Ordner erstellt: $cat"
        }
    }

    $files = Get-ChildItem $Desktop -File

    foreach ($file in $files) {
        $matched = $false

        foreach ($category in $Categories.Keys) {
            if ($Categories[$category] -contains $file.Extension.ToLower()) {
                Move-Item $file.FullName -Destination (Join-Path $Desktop $category) -Force
                Write-Host "$($file.Name) -> $category"
                Write-Log "$($file.Name) -> $category"
                $matched = $true
                break
            }
        }

        if (-not $matched) {
            Write-Log "Nicht zugeordnet: $($file.Name)"
        }
    }

    Read-LogSummary
    Show-QuoteOfTheDay
}

# -------------------------------
# PRO MODE
# -------------------------------
function Sort-ProMode {
    param($Desktop)

    Write-Host "`nPro Mode gestartet"
    Write-Log "Pro Mode gestartet"

    $extensions = (Read-Host "Dateiendungen (.png,.jpg,.pdf)").Split(",") |
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
        New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
        Write-Log "Neuer Ordner erstellt: $name"
    }
    elseif ($choice -ge 1 -and $choice -le $folders.Count) {
        $targetFolder = $folders[$choice - 1].FullName
    }
    else {
        Write-Host "Ungültige Auswahl"
        return
    }

    Get-ChildItem $Desktop -File | Where-Object {
        $extensions -contains $_.Extension.ToLower()
    } | ForEach-Object {
        Move-Item $_.FullName -Destination $targetFolder -Force
        Write-Log "$($_.Name) -> $(Split-Path $targetFolder -Leaf)"
    }

    Read-LogSummary
    Show-QuoteOfTheDay
}

# -------------------------------
# AUTO DELETE
# -------------------------------
function Auto-Delete {

    Write-Log "Auto-Delete gestartet"

    $folder = Read-Host "Ordnerpfad eingeben"
    if (-not (Test-Path $folder)) {
        Write-Host "Ordner existiert nicht"
        return
    }

    $unit = Read-Host "Einheit (m = Minuten, h = Stunden, d = Tage)"
    if ($unit -notin @("m","h","d")) {
        Write-Host "Ungültige Einheit"
        return
    }

    $value = Read-Host "Wie alt sollen die Dateien sein? (Zahl)"
    if (-not ($value -as [int]) -or $value -le 0) {
        Write-Host "Ungültige Zeitangabe"
        return
    }

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

    Write-Host "`nZu löschende Dateien:"
    $files | ForEach-Object { Write-Host "- $($_.Name)" }

    if ((Read-Host "Wirklich löschen? (y/n)").ToLower() -ne "y") {
        Write-Log "Auto-Delete abgebrochen"
        return
    }

    $files | ForEach-Object {
        Remove-Item $_.FullName -Force
        Write-Log "Gelöscht: $($_.Name)"
    }

    Write-Log "Auto-Delete abgeschlossen"
}

# -------------------------------
# SYSTEMINFOS
# -------------------------------
function Show-SystemInfo {
    Write-Log "Systeminfos abgefragt"

    Write-Host "`nSysteminformationen:`n"
    Write-Host "CPU : $((Get-CimInstance Win32_Processor)[0].Name)"
    Write-Host "RAM : $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB,2)) GB"
    Write-Host "GPU : $((Get-CimInstance Win32_VideoController)[0].Name)"
    Write-Host "OS  : $((Get-CimInstance Win32_OperatingSystem).Caption)"
}

# =====================================================
# HAUPTMENÜ (MIT LOOP + SAUBEREM EXIT)
# =====================================================

$exitProgram = $false

do {
    Clear-Host

    Write-Host @"
====================================
   DESKTOP ASSISTANT v1.0
====================================
"@

    Write-Host "Was möchtest du tun?"
    Write-Host "1) Desktop sortieren"
    Write-Host "2) Alte Dateien automatisch löschen"
    Write-Host "3) Systeminformationen anzeigen"
    Write-Host "0) Beenden"

    $choice = Read-Host "Bitte wählen"

    switch ($choice) {
        "1" {
            $mode = Read-Host "Easy oder Pro?"
            if ($mode.ToLower() -eq "easy") {
                Sort-EasyMode -Desktop $desktop -Categories $EasyCategories
            }
            elseif ($mode.ToLower() -eq "pro") {
                Sort-ProMode -Desktop $desktop
            }
            else {
                Write-Host "Ungültiger Modus"
            }
        }
        "2" { Auto-Delete }
        "3" { Show-SystemInfo }
        "0" {
            Write-Log "Programm beendet"
            Write-Host "Programm wird beendet..."
            $exitProgram = $true
        }
        default {
            Write-Host "Ungültige Auswahl"
        }
    }

    if (-not $exitProgram) {
        Write-Host "`nDrücke ENTER um zum Menü zurückzukehren..."
        Read-Host
    }

} while (-not $exitProgram)
