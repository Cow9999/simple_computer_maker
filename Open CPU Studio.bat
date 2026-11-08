@echo off
setlocal
cd /d "%~dp0"

where node >nul 2>nul
if errorlevel 1 (
  for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\OpenJS.NodeJS.LTS_Microsoft.Winget.Source_8wekyb3d8bbwe\node-v*-win-x64") do (
    if exist "%%~fD\node.exe" (
      set "PATH=%%~fD;%PATH%"
      goto :node_found
    )
  )
)

:node_found
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js is required. Install Node.js LTS, then open CPU Studio again.
  echo Download: https://nodejs.org/
  pause
  exit /b 1
)

if not exist "node_modules\vite\bin\vite.js" (
  echo Setting up CPU Studio for first use...
  call npm.cmd install
  if errorlevel 1 (
    echo Dependency installation failed. Check your internet connection and try again.
    pause
    exit /b 1
  )
)

echo Starting CPU Studio in your browser. Keep this window open while you use the app.
call npm.cmd run dev -- --open
