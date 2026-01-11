# Desktop Assistant – Benutzeranleitung

Diese Anleitung erklärt kurz, wie das PowerShell‑Script ausgeführt wird und welche Voraussetzungen nötig sind.
Gedacht ist sie als **README.md** für das GitHub‑Repository. Screenshots kannst du später ergänzen.

---

## Voraussetzungen

* **Windows 10 oder Windows 11**
* **PowerShell 7 (x64)** – *empfohlen*

  > Das Script wurde hauptsächlich mit PowerShell 7 (64‑Bit) getestet und wird damit empfohlen.
* Berechtigung, PowerShell‑Skripte auszuführen

### PowerShell 7 installieren (falls nicht vorhanden)

Download: [https://learn.microsoft.com/powershell/](https://learn.microsoft.com/powershell/)

Nach der Installation heißt der Befehl:

```powershell
pwsh
```

---

## Repository klonen oder herunterladen

### Option 1: Git

```bash
git clone https://github.com/<dein-username>/<repository-name>.git
```

### Option 2: ZIP

* Auf **Code → Download ZIP** klicken
* ZIP entpacken

---

## Script ausführen

1. **PowerShell 7 (x64)** öffnen
2. In den Projektordner wechseln:

```powershell
cd "Pfad\zum\Projektordner"
```

3. Falls nötig, Execution Policy für die aktuelle Session setzen:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

4. Script starten:

```powershell
./Desktop-Assistant.ps1
```

*(Dateiname ggf. anpassen)*

---

## Programmstart & Bedienung

* Nach dem Start erscheint ein **Hauptmenü**
* Der Benutzer kann zwischen verschiedenen Modi wählen (z. B. Easy / Pro)
* Aktionen werden automatisch **geloggt** (Logdateien nach Datum)
* Je nach Modus werden Dateien sortiert, verschoben oder analysiert

> **Hinweis:** Einige Funktionen (z. B. Auto‑Delete) können Dateien dauerhaft löschen. Bitte sorgfältig lesen, bevor Aktionen bestätigt werden.

---

## Empfohlene Nutzung

* Verwende das Script **nicht** direkt auf sensiblen Ordnern (z. B. Systemordner)
* Teste neue Funktionen zuerst in einem **Testordner**
* Lies die Konsolenausgaben aufmerksam, bevor du bestätigst

---

## Troubleshooting

**Script startet nicht?**

* Stelle sicher, dass PowerShell 7 (x64) verwendet wird (`$PSVersionTable`)
* Prüfe die Execution Policy

**Zugriff verweigert?**

* PowerShell ggf. als Administrator starten

---

## Hinweis

Dieses Projekt ist ein **Schulprojekt** und dient Lern‑ und Demonstrationszwecken.

---

*Autor: Urim Krasniqi*
# M122-Project-Desktop_Sorter