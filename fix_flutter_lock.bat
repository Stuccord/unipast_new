@echo off
echo Terminating Flutter and Dart processes...
taskkill /F /IM dart.exe /IM flutter.exe /T
echo.
echo Removing lock files...
del /F /Q "C:\Users\16789\Downloads\flutter_windows_3.41.4-stable\flutter\bin\cache\lockfile"
del /F /Q "C:\Users\16789\Downloads\flutter_windows_3.41.4-stable\flutter\bin\cache\flutter.bat.lock"
echo.
echo Done! Please try running Flutter now.
pause
