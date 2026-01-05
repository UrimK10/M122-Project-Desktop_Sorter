# -----------------------------------------
# Desktop Assistant – Easy / Pro Mode
# -----------------------------------------

$desktop = "$env:USERPROFILE\OneDrive - TBZ\Desktop"
$logBase = "C:\DesktopSorterLogs"

# -------------------------------
# LOGGING FUNKTIONEN
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
# WEISHEIT DES TAGES (API)
# -------------------------------
function Show-QuoteOfTheDay {

    Write-Host "`nWeisheit des Tages:`n"

    try {
        $response = Invoke-RestMethod -Uri "https://api.quotable.io/random" -Method Get
        $quote = "`"$($response.content)`" — $($response.author)"

        Write-Host $quote
        Write-Log "Weisheit des Tages: $quote"
    }
    catch {
        Write-Host "Keine Weisheit verfügbar (keine Internetverbindung)"
        Write-Log "Weisheit des Tages konnte nicht geladen werden"
    }
}

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

    $files = Get-ChildItem $Desktop | Where-Object {
        -not $_.PSIsContainer
    }

    foreach ($file in $files) {
        foreach ($category in $Categories.Keys) {
            if ($Categories[$category] -contains $file.Extension.ToLower()) {
                Move-Item $file.FullName -Destination (Join-Path $Desktop $category) -Force
                Write-Host "$($file.Name) -> $category"
                Write-Log "$($file.Name) -> $category"
                break
            }
        }
    }

    Write-Log "Easy Mode abgeschlossen"
    Read-LogSummary
    Show-QuoteOfTheDay
}

# -------------------------------
# PRO MODE
# -------------------------------
function Sort-ProMode {
    param($Desktop)

    Write-Host "`nProfessional Mode gestartet"
    Write-Log "Pro Mode gestartet"

    Write-Host "Du wählst Dateiendungen und einen Zielordner."

    $inputExt = Read-Host "Dateiendungen (z.B. .png,.jpg,.xlsx)"
    $extensions = $inputExt.Split(",") | ForEach-Object { $_.Trim().ToLower() }

    Write-Log "Dateiendungen: $($extensions -join ', ')"

    $folders = Get-ChildItem $Desktop -Directory

    Write-Host "`nZielordner wählen:"
    $i = 1
    foreach ($folder in $folders) {
        Write-Host "$i) $($folder.Name)"
        $i++
    }
    Write-Host "0) Neuen Ordner erstellen"

    $choice = Read-Host "Nummer wählen"

    if ($choice -eq "0") {
        $newFolderName = Read-Host "Name des neuen Ordners"
        $targetFolder = Join-Path $Desktop $newFolderName
        if (-not (Test-Path $targetFolder)) {
            New-Item -ItemType Directory -Path $targetFolder | Out-Null
            Write-Log "Neuer Ordner erstellt: $newFolderName"
        }
    }
    elseif ($choice -ge 1 -and $choice -le $folders.Count) {
        $targetFolder = $folders[$choice - 1].FullName
    }
    else {
        Write-Host "Ungültige Auswahl"
        Write-Log "Pro Mode abgebrochen (ungültige Ordnerwahl)"
        return
    }

    Write-Log "Zielordner: $(Split-Path $targetFolder -Leaf)"

    $files = Get-ChildItem $Desktop | Where-Object {
        -not $_.PSIsContainer -and
        $extensions -contains $_.Extension.ToLower()
    }

    foreach ($file in $files) {
        Move-Item $file.FullName -Destination $targetFolder -Force
        Write-Host "$($file.Name) -> $(Split-Path $targetFolder -Leaf)"
        Write-Log "$($file.Name) -> $(Split-Path $targetFolder -Leaf)"
    }

    Write-Log "Pro Mode abgeschlossen"
    Read-LogSummary
    Show-QuoteOfTheDay
}

# -------------------------------
# AUTO DELETE (OPTIONAL)
# -------------------------------
function Auto-Delete {
    Write-Log "Auto-Delete gestartet"

    $folder = Read-Host "Pfad des Ordners"
    if (-not (Test-Path $folder)) {
        Write-Host "Ordner existiert nicht"
        Write-Log "Auto-Delete abgebrochen (Ordner existiert nicht)"
        return
    }

    $timeValue = Read-Host "Alter der Dateien (Zahl)"
    $unit = Read-Host "Einheit (m/h/d)"

    switch ($unit.ToLower()) {
        "m" { $cutoff = (Get-Date).AddMinutes(-$timeValue) }
        "h" { $cutoff = (Get-Date).AddHours(-$timeValue) }
        "d" { $cutoff = (Get-Date).AddDays(-$timeValue) }
        default { $cutoff = (Get-Date).AddDays(-$timeValue) }
    }

    $files = Get-ChildItem $folder | Where-Object {
        -not $_.PSIsContainer -and $_.LastWriteTime -lt $cutoff
    }

    foreach ($file in $files) {
        Remove-Item $file.FullName -Force
        Write-Log "Gelöscht: $($file.Name)"
    }

    Write-Log "Auto-Delete abgeschlossen"
}

# -------------------------------
# SYSTEM INFORMATIONEN
# -------------------------------
function Show-SystemInfo {

    Write-Host "`nSysteminformationen:`n"
    Write-Log "Systeminformationen abgefragt"

    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    Write-Host "CPU : $($cpu.Name)"
    Write-Log "CPU: $($cpu.Name)"

    $ramGB = [Math]::Round(
        (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2
    )
    Write-Host "RAM : $ramGB GB"
    Write-Log "RAM: $ramGB GB"

    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    Write-Host "GPU : $($gpu.Name)"
    Write-Log "GPU: $($gpu.Name)"

    $os = Get-CimInstance Win32_OperatingSystem
    Write-Host "OS  : $($os.Caption)"
    Write-Log "OS: $($os.Caption)"
}

# -------------------------------
# HAUPTMENÜ
# -------------------------------
Write-Host "`nWas möchtest du tun?"
Write-Host "1) Desktop sortieren"
Write-Host "2) Alte Dateien automatisch löschen"
Write-Host "3) Systeminformationen anzeigen"

$choice = Read-Host "Bitte 1, 2 oder 3 wählen"

switch ($choice) {
    "1" {
        $mode = Read-Host "Welchen Modus willst du? (Easy / Pro)"
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
    default { Write-Host "Ungültige Auswahl" }
}
