$ErrorActionPreference = "Stop"
$shim = "$env:LOCALAPPDATA\awal-nodejs\ps-shim"
$server = "$env:LOCALAPPDATA\awal-nodejs\Data\server"
if (!(Test-Path "$server\bundle-electron.js")) { Write-Error "awal server bundle not found. Run 'npx awal status' once first (it installs the bundle), then re-run this script." }
New-Item -ItemType Directory -Force -Path $shim | Out-Null
@"
@echo off
powershell -NoProfile -Command "`$cl=(Get-CimInstance Win32_Process -Filter 'ProcessId=%2' -ErrorAction SilentlyContinue).CommandLine; if(`$cl -match 'awal|payments-mcp|bundle-electron'){'awal-cli'}else{`$cl}"
"@ | Set-Content "$shim\ps.cmd" -Encoding ascii
Get-CimInstance Win32_Process -Filter "Name='electron.exe'" | Where-Object { $_.CommandLine -match "awal-nodejs" } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep 2
New-Item -ItemType Directory -Force -Path C:\tmp | Out-Null
Remove-Item C:\tmp\payments-mcp-ui.lock -ErrorAction SilentlyContinue
$env:PATH = "$shim;$env:PATH"
$env:STARTED_BY_CLI = "true"
$env:WALLET_STANDALONE = "true"
Start-Process -FilePath "$server\node_modules\electron\dist\electron.exe" -ArgumentList "`"$server\bundle-electron.js`"" -WindowStyle Hidden
Start-Sleep 12
if (Test-Path C:\tmp\payments-mcp-ui.lock) { Write-Host "Wallet server started (pid $(Get-Content C:\tmp\payments-mcp-ui.lock)). Try: npx awal status" } else { Write-Warning "Lock file not found yet - give it a few more seconds, then run: npx awal status" }
