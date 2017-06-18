<#
.SYNOPSIS
    Performs and in-depth removal of Java
 
.DESCRIPTION
    Removes Java using official uninstallers, then removes the Java directory and registry keys manually
 
.PARAMETER Force
    Use with caution. If this switch is set, additional registry keys related to Java are removed.
 
.PARAMETER IgnoreGUIDs
    An array of Product GUIDs that this script should ignore. Ensure that you match the GUIDs with the ExcludedFolders parameter.
 
.PARAMETER ExcludedFolders
    An array of subfolders of the Java directory to ignore. Ensure that you match these directories with the product GUIDs in the IgnoreGUIDs paramter.
 
.OUTPUTS
    Saves a log to "C:\Windows\Temp\FullJavaRemovalScript.log"
 
.NOTES
    Version:        2.0
    Author:         Matthew Thompson
    Creation Date:  2016-01-07
    Purpose/Change: Cleanup for Blog
 
.EXAMPLE
    &"JavaRemoval.ps1" -Force
 
.EXAMPLE
    &"JavaRemoval.ps1" -IgnoreGUIDs @("{26A24AE4-039D-4CA4-87B4-2F64180112F0}", "{26A24AE4-039D-4CA4-87B4-2F32180112F0}") -ExcludedFolders @("jre1.8.0_112")
#>
 
Param
(
    [switch]$Force,
    $IgnoreGUIDs = @(),
    $ExcludedFolders = @()
)
 
#Logging information
$ScriptStartTime = [DateTime]::Now
$Log=""
$Log+="Script started at:`r`n"
$Log+="`t"+$ScriptStartTime.ToString()+"`r`n"
 
#Fix for Powershell 2.0. Searches through an array for an object.
function Get-Contains
{
    Param([System.String[]]$Array, [String]$Object)
    foreach($Item in $Array)
    {
        if ($Item -eq $Object)
        {
            return $true
        }
    }
    return $false
}
 
#Tasks to Kill
$Tasks = @("iexplorer.exe","iexplore.exe","firefox.exe","jusched.exe","chrome.exe","javaw.exe","jqs.exe")
$Log+="Tasks to kill:`r`n"
$Tasks | ForEach-Object -Process {$Log+="`t"+$_+"`r`n";}
 
#GUIDs to find
#These GUIDs are the prefixes for all Java products version 6 and up
$GUIDs = @("{26A24AE4-039D-4CA4-87B4-*", "{3248F0A8-6813-11D6-A77B-*", "{7148F0A8-6813-11D6-A77B-*")
$Log+="GUIDs to search:`r`n"
$GUIDs | ForEach-Object -Process {$Log+="`t"+$_+"`r`n";}
 
#Ignore GUIDS (Current Java Version)
$Log+="GUIDs to exclude:`r`n"
$IgnoreGUIDs | ForEach-Object -Process {$Log+="`t"+$_+"`r`n";}
 
#Folders to exclude from manual uninstall
$Log+="Folders to exclude:`r`n"
$ExcludedFolders | ForEach-Object -Process {$Log+="`t"+$_+"`r`n";}
 
if ($Force)
{
    $Log+="Force Set`r`n"
}
 
#Kill the tasks that tend to interrupt installs
Write-Host "Killing Tasks"
$Log+="Killing Tasks`r`n"
foreach ($Task in $Tasks)
{
    $Log+="`tKilling: "+$Task+"`r`n"
	start-process "taskkill" -ArgumentList @("/F","/IM",$Task) -ErrorAction SilentlyContinue -NoNewWindow -wait
}
 
Write-Host "Un-Installing Old Java Versions"
$ToRemove=@()
#Search the registry for the GUIDs
foreach($GUID in $GUIDs)
{
	$ToRemove += Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Where-Object -FilterScript {
		$_.Name -like "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"+$GUID
	}
	$ToRemove += Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Where-Object -FilterScript {
		$_.Name -like "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"+$GUID
	}
}
 
$Log+="Java to remove (Ignore GUIDs will show here too, but will not be removed)`r`n"
$ToRemove | ForEach-Object -Process {$Log+="`t"+$_.PSPath+"`r`n";}
 
$Log+="Uinstalling Old Java`r`n"
$ExitCode = 0;#0=Success #This will be used to report back to the calling application (SCCM?)
$RebootRequired=$false;
$RemovalStatus = @(); #Used to perform additional actions based on ExitCodes
foreach ($Java in $ToRemove)
{
    $GUID = $Java.PSChildName
    if (-not (Get-Contains -Array $IgnoreGUIDs -Object $GUID))
    {
	    Write-Host "Removing"$Java.GetValue("DisplayName")
        $Log+="`tRemoving"+$Java.GetValue("DisplayName")+"`r`n"
	    #$GUID | Out-File C:\Windows\Temp\JavaLog.log -Append #Logging for troubleshooting
        $Log+="`t`t"+$GUID.ToString()+"`r`n"
	    $Process = (start-process "MsiExec.exe" -wait -PassThru -ArgumentList @("/X",$GUID,"/qn","/norestart"))
	    #$Process.ExitCode | Out-File C:\Windows\Temp\JavaLog.log -Append #Logging for troubleshooting
        if ($Process.ExitCode -ne $null)
        {
            Write-Host ("Uninstall exited with: "+$Process.ExitCode.ToString())
            $Log+="`t`t"+$Process.ExitCode.ToString()+"`r`n"
	    }
        elseif ($Process.ExitCode -eq $null)
        {
            Write-Host "Could not determine uninstall exit code!"
            $Log+="`t`t"+"Exit code not determined."+"`r`n"
        }
        if ($Process.ExitCode -ne $null -and $Process.ExitCode -ne 0)
	    {
            $RemovalStatus += @{ExitCode=$Process.ExitCode; GUID=$GUID};
		    $ExitCode = $Process.ExitCode #Return the last non-zero exit code (If any)
	    }
        if ($Process.ExitCode -eq 1618 -or $Process.ExitCode -eq 1641 -or $Process.ExitCode -eq 3010 )
        {
            $RebootRequired = $true;
        }
    }
    else
    {
        $Log+="`tSkipped: "+$Java.GetValue("DisplayName")+"`r`n"
        $Log+="`t`t"+$GUID.ToString()+"`r`n"
    }
}
 
#Retrieve Java install directories
$InstalledFolders = @()
$InstalledFolders += Get-ChildItem -Path "C:\Program Files (x86)\Java" -ErrorAction SilentlyContinue
$InstalledFolders += Get-ChildItem -Path "C:\Program Files\Java" -ErrorAction SilentlyContinue
$Log+="Removing Folders`r`n"
 
#Remove old Java installs
foreach ($InstalledFolder in $InstalledFolders)
{
    if ((Get-Contains -Array $ExcludedFolders -Object $InstalledFolder.Name.ToLower()) -eq $false)
    {
        Write-Host ("Removing: "+$InstalledFolder.FullName)
        $Log+="`tRemoving folder: "+$InstalledFolder.FullName+"`r`n"
        Remove-Item -Path $InstalledFolder.FullName -Force -Recurse -ErrorAction SilentlyContinue
    }
    else
    {
        $Log+="`tSkipped folder: "+$InstalledFolder.FullName+"`r`n"
    }
}
 
if ($Force)
{
    Write-Host "Force flag set. Manually removing additional registry keys and Java Directory."
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
    $Log+="Force flag set`r`n"
 
    #Common Java Registry Removals
    $KeysToRemove = @("HKLM:\SOFTWARE\JavaSoft", "HKLM:\SOFTWARE\JreMetrics", "HKLM:\SOFTWARE\Wow6432Node\JavaSoft",
     "HKLM:\SOFTWARE\Wow6432Node\JreMetrics", "HKCR:\CLSID\{4299124F-F2C3-41b4-9C73-9236B2AD0E8F}",
     "HKCR:\Wow6432Node\CLSID\{4299124F-F2C3-41b4-9C73-9236B2AD0E8F}")
 
    Get-ChildItem “HKCR:\Installer\Products” | Where { $_.GetValue('ProductName') -like '*Java * Update *'} | ForEach-Object {$KeysToRemove += $_.PSPath}
    Get-ChildItem “HKCR:\Installer\Features” | Where { $_.Property.Contains("jrecore") } | ForEach-Object {$KeysToRemove += $_.PSPath}
 
    $Log+="Removing registry keys`r`n"
    foreach($Java in $ToRemove)
    {
        Remove-Item -Path $Java.PSPath -Force -ErrorAction SilentlyContinue | Out-Null
        Write-Host ("Removed "+$Java.PSPath)
        $Log+=("`tRemoving "+$Java.PSPath+"`r`n")
    }
 
    foreach ($Key in $KeysToRemove)
    {
        Remove-Item -Path $Key -Force -Recurse -ea SilentlyContinue | Out-Null
        Write-Host "Removed $Key"
        $Log+="`tRemoving $Key`r`n"
    }
}
 
#Handle Exit codes
#Exit code 1605 or 1614 tend to occur when java was incompletly removed before. This removes the product from add-remove programs.
$Log+="Performing Additional Actions ("+$RemovalStatus.Count.ToString()+")`r`n";
foreach($Status in $RemovalStatus)
{
    if ($Status.ExitCode -eq 1605 -or $Status.ExitCode -eq 1614 -or $Force)
    {
        #Manually remove the keys
        if (Test-Path -Path ("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"+$Status.GUID))
        {
            $Log+="Removing: "+("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"+$Status.GUID)+"`r`n"
            Remove-Item -Path ("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"+$Status.GUID) -Force -ErrorAction SilentlyContinue;
        }
        if (Test-Path -Path ("HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"+$Status.GUID))
        {
            $Log+="Removing: "+("HKLM:\Wow6432Node\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"+$Status.GUID)+"`r`n"
            Remove-Item -Path ("HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"+$Status.GUID) -Force -ErrorAction SilentlyContinue;
        }
    }
}
 
#Write out log
$ScriptEndTime = [DateTime]::Now
$Log+="Script End Time:`r`n"
$Log+="`t"+$ScriptEndTime.ToString()+"`r`n"
$Log+="`tTotal Span:`r`n"
$Log+="`t`t"+($ScriptEndTime - $ScriptStartTime).ToString()+"`r`n"
 
$Log | Out-File -FilePath "C:\Windows\Temp\FullJavaRemovalScript.log"
 
#Write exit code for calling application
if ($RebootRequired)
{
    return 3010; #Requires Reboot (SCCM should handle well)
}
else
{
    return $ExitCode; #Other Exit Code retrieved from uninstallers
}
