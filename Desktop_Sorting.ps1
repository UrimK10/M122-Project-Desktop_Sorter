# -----------------------------------------
# Desktop Assistant – Easy / Pro Mode
# -----------------------------------------

$desktop = "$env:USERPROFILE\OneDrive - TBZ\Desktop"

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

    Write-Host "`nEasy Mode:"
    Write-Host "Dateien werden automatisch nach Typ sortiert (Bilder, Videos, Dokumente etc.)`n"

    foreach ($cat in $Categories.Keys) {
        $path = Join-Path $Desktop $cat
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path | Out-Null
        }
    }

    $files = Get-ChildItem $Desktop | Where-Object {
        -not $_.PSIsContainer
    }

    $movedCount = 0

    foreach ($file in $files) {
        foreach ($category in $Categories.Keys) {
            if ($Categories[$category] -contains $file.Extension.ToLower()) {
                Move-Item $file.FullName -Destination (Join-Path $Desktop $category) -Force
                Write-Host "$($file.Name) -> $category"
                $movedCount++
                break
            }
        }
    }

    Write-Host "`nEasy Mode abgeschlossen. Dateien verschoben: $movedCount"
}

# -------------------------------
# PRO MODE
# -------------------------------
function Sort-ProMode {
    param($Desktop)

    Write-Host "`nProfessional Mode:"
    Write-Host "Du wählst Dateiendungen UND den Zielordner selbst."
    Write-Host "Beispiel: .png,.jpg -> Ordner 'Projekt'"
    Write-Host "Nur passende Dateien werden verschoben.`n"

    # Dateiendungen
    $inputExt = Read-Host "Gib die Dateiendungen ein (z.B. .png,.jpg,.xlsx)"
    $extensions = $inputExt.Split(",") | ForEach-Object { $_.Trim().ToLower() }

    if ($extensions.Count -eq 0) {
        Write-Host "Keine Dateiendungen angegeben – Abbruch"
        return
    }

    # Ordner auf Desktop auflisten
    $folders = Get-ChildItem $Desktop -Directory

    Write-Host "`nWähle einen Zielordner:"
    $index = 1
    foreach ($folder in $folders) {
        Write-Host "$index) $($folder.Name)"
        $index++
    }
    Write-Host "0) Neuen Ordner erstellen"

    $choice = Read-Host "Bitte Nummer wählen"

    if ($choice -eq "0") {
        $newFolderName = Read-Host "Name des neuen Ordners"
        $targetFolder = Join-Path $Desktop $newFolderName

        if (-not (Test-Path $targetFolder)) {
            New-Item -ItemType Directory -Path $targetFolder | Out-Null
            Write-Host "Ordner erstellt: $newFolderName"
        }
    }
    elseif ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $folders.Count) {
        $targetFolder = $folders[$choice - 1].FullName
    }
    else {
        Write-Host "Ungültige Auswahl – Abbruch"
        return
    }

    # Dateien verschieben
    $files = Get-ChildItem $Desktop | Where-Object {
        -not $_.PSIsContainer -and
        $extensions -contains $_.Extension.ToLower()
    }

    $movedCount = 0
    foreach ($file in $files) {
        Move-Item $file.FullName -Destination $targetFolder -Force
        Write-Host "$($file.Name) -> $(Split-Path $targetFolder -Leaf)"
        $movedCount++
    }

    Write-Host "`nPro Mode abgeschlossen. Dateien verschoben: $movedCount"
}

# -------------------------------
# AUTO DELETE (OPTIONAL)
# -------------------------------
function Auto-Delete {
    $folder = Read-Host "Pfad des Ordners für automatisches Löschen"
    if (-not (Test-Path $folder)) {
        Write-Host "Ordner existiert nicht!"
        return
    }

    $timeValue = Read-Host "Wie alt sollen die Dateien sein? (Zahl)"
    if (-not [int]::TryParse($timeValue, [ref]0)) {
        Write-Host "Ungültige Zahl"
        return
    }

    $unit = Read-Host "Einheit (m=Minuten, h=Stunden, d=Tage)"
    switch ($unit.ToLower()) {
        "m" { $cutoff = (Get-Date).AddMinutes(-$timeValue) }
        "h" { $cutoff = (Get-Date).AddHours(-$timeValue) }
        "d" { $cutoff = (Get-Date).AddDays(-$timeValue) }
        default { $cutoff = (Get-Date).AddDays(-$timeValue) }
    }

    $files = Get-ChildItem $folder | Where-Object {
        -not $_.PSIsContainer -and $_.LastWriteTime -lt $cutoff
    }

    $count = 0
    foreach ($file in $files) {
        Remove-Item $file.FullName -Force
        $count++
    }

    Write-Host "`nAuto-Delete abgeschlossen. Dateien gelöscht: $count"
}

# -------------------------------
# HAUPTMENÜ
# -------------------------------
Write-Host "`nWas möchtest du tun?"
Write-Host "1) Desktop sortieren"
Write-Host "2) Alte Dateien automatisch löschen"

$choice = Read-Host "Bitte 1 oder 2 wählen"

switch ($choice) {
    "1" {
        $mode = Read-Host "Welchen Modus willst du? (Easy / Pro)"

        switch ($mode.ToLower()) {
            "easy" { Sort-EasyMode -Desktop $desktop -Categories $EasyCategories }
            "pro"  { Sort-ProMode  -Desktop $desktop }
            default { Write-Host "Ungültiger Modus" }
        }
    }
    "2" { Auto-Delete }
    default { Write-Host "Ungültige Auswahl" }
}
