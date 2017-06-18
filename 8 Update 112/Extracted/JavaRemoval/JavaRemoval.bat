If "%PROCESSOR_ARCHITEW6432%"=="" GOTO Native
 
%systemroot%\Sysnative\windowsPowershell\V1.0\PowerShell.exe -NoProfile -ExecutionPolicy Bypass -file "%~dp0JavaRemoval.ps1"
 
GOTO END
 
:Native
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -file "%~dp0JavaRemoval.ps1"
 
:END

exit %errorlevel%