MD "C:\ProgramData\Oracle\Java"
copy "%~dp0java.settings.cfg" "C:\ProgramData\Oracle\Java\java.settings.cfg"
msiexec.exe /i "%~dp0jre1.8.0_11264.msi" /qn /l*v "C:\Windows\Temp\JavaInstallLog.log"
SET return=%ERRORLEVEL%
del "C:\ProgramData\Oracle\Java\java.settings.cfg"
exit /b %RETURN%