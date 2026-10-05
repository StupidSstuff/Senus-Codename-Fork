@echo off
setlocal

echo Codename Engine Classic Renderer - FFmpeg
echo.

set /p "renderFolder=Enter the song render folder name: "
set /p "renderName=Enter the output video name: "
set /p "vidFPS=Enter the image framerate (default 60): "
if "%vidFPS%"=="" set "vidFPS=60"

set /p "useLossless=Are the frames PNG? (y/n, default n): "
if /i "%useLossless%"=="y" (
    set "ext=png"
) else (
    set "ext=jpg"
)

echo.
echo Starting FFmpeg...
ffmpeg -r %vidFPS% -i "%~dp0%renderFolder%\%%07d.%ext%" -c:v libx264 -pix_fmt yuv420p "%renderName%.mp4"

pause
endlocal
