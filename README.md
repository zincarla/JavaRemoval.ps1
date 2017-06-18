# JavaRemoval.ps1
JavaRemoval is a script designed to remove all versions of Java.

## Usage
### To remove all versions
Inside of a PowerShell console enter the following:
```
&"<Path to script>"
```
Example:
```
&"C:\Scripts\JavaRemoval.ps1"
```
### To remove all Java Versions Except a specific version
Inside of a PowerShell console enter the following:
```
&"<Path to script>" -IgnoreGUIDs @("{XXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}") -ExcludedFolders @("jre1.X.X_XXX")
```
Example, to remove all versions of Java except 8 Update 112:
```
&"C:\Scripts\JavaRemoval.ps1" -IgnoreGUIDs @("{26A24AE4-039D-4CA4-87B4-2F64180112F0}", "{26A24AE4-039D-4CA4-87B4-2F32180112F0}") -ExcludedFolders @("jre1.8.0_112")
```

# Java Install Package
This is an example package for creating a full solution to managing Java deployments through SCCM. This solution avoids all issues outlined in [my blog post](http://ziviz.us/WP/2017/06/18/installing-java-through-sccm/)

## Overview
There are three applications we need to create in SCCM.

An install package for the current version of Java 32-bit
An install package for the current version of Java 64-bit
Lastly, an uninstall package for all other versions of Java
The example package available on this page contains all the scripts required to build this solution in SCCM. I added ".placeholder" files to give an example of where the Java Install files should go. If you were to replace those files with the actual .MSI files for Java 8 Update 112, then this package should be complete, and ready to build in SCCM. Otherwise, you will need to edit several files to reflect whatever version of Java you are installing.
### This Install Application Packages
These packages are fairly straight forward except that we need to account for the installation config file that must be installed on the client machine, and then removed after the install completes. The 32-bit and 64-bit package are nearly identical.
#### How it Works
The Install.bat file copies the config file that is stored within the same folder, to the appropriate location on the client machine. This ensures that the install completes silently. The bat file then installs the Java MSI also located in the same directory. After the install completes, the bat file then removes the config file to ensure that manual installation attempts don't lead to confusion by invisible install dialogs.
### The Uninstall Application Package
This package will utilize PowerShell heavily. Both the install file and the detection script are PowerShell.
#### How it Works
First the JavaRemoval.bat which ensures that the JavaRemoval.ps1 PowerShell script is run in the correct bit-mode for the machine. The JavaRemoval.ps1 then uninstalls are versions of Java that are not specifically white-listed in the script. This ensures that your environment will have old vulnerable versions of Java removed.
## Creating the Java Install Solution
This section will explain the steps required to create the Java Installation solution for SCCM.
### Pre Setup
First, extract the files from the example on this page to a working directory. Rename the folder as needed. I suggest sticking with the version format though. ("8 Update 112" for example)

Second, the Java Setup files must be downloaded and the MSI installer extracted. To do this:

1. Download the Java SE JRE Offline installers from the Java SE Downloads page
2. Run the installers but do not click next nor continue the installation!
3. Once the installer is visible, navigate to "C:\Users\[Your UserName]\AppData\LocalLow\Oracle\Java" or "%APPDATA%\..\LocaLow\Oracle\Java". Inside this directory you should see a folder matching the version of Java you started the installer for. For example "jre1.8.0_112_x64". Copy everything inside the folder to the appropriate x86 or x64 folder located in the "\Extracted" directory from the example download. Repeat this as needed for other bit version of Java. (So once for 32 bit, and once for 64 bit)

#### Script Changes Required
##### The Install Config Files
Modify the "Extracted\x64\java.settings.cfg" and "Extracted\x86\java.settings.cfg" files to reflect your environment's needs. The defaults however, are likely good enough.
##### The Install Batch Files
Modify the "Extracted\x64\Install.bat" and "Extracted\x86\Install.bat" files to fix the MSI file name. In the example below, the section in bold needs to be changed to match the MSI file you copied into that folder.
```
MD "C:\ProgramData\Oracle\Java"
copy "%~dp0java.settings.cfg" "C:\ProgramData\Oracle\Java\java.settings.cfg"
msiexec.exe /i "%~dp0jre1.8.0_11264.msi" /qn /l*v "C:\Windows\Temp\JavaInstallLog.log"
SET return=%ERRORLEVEL%
del "C:\ProgramData\Oracle\Java\java.settings.cfg"
exit /b %RETURN%
```
##### Retrieve the new Product GUIDs and Directory Name
Install downloaded Java installer on a sample machine. Then:
1. Open Regedit.exe and navigate to "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" for 64bit Java and search through the keys until you find the one matching the Java you just installed. The name of the key is the Product GUID for that version of Java. Make sure you mark it down somewhere, as it will be required for the next step.
2. Open Regedit.exe and navigate to "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" for 32bit Java and search through the keys until you find the one matching the Java you just installed. The name of the key is the Product GUID for that version of Java. Make sure you mark it down somewhere, as it will be required for the next step.
3. Navigate to the Java install Directories "C:\Program Files (x86)\Java" and "C:\Program Files\Java" and make a note of the folder matching the version of Java you just installed. This will likely be the same in both directories. (Example: "jre1.8.0_112")
##### The Java Removal Script
Modify the "Extracted\JavaRemoval\JavaRemoval.ps1" to reflect the latest Java that you downloaded. To do this, change the Param block to reflect the GUIDs for the versions of Java you are installing, and the install directory folder. This should be the same information you retrieved in the previous section. Note that if the folders are the same, you do not need to enter them in twice.
```
Param
(
    [switch]$Force,
    $IgnoreGUIDs = @("{26A24AE4-039D-4CA4-87B4-2F64180112F0}", "{26A24AE4-039D-4CA4-87B4-2F32180112F0}"),
    $ExcludedFolders = @("jre1.8.0_112")
)
```
##### The Java Removal Detection Script
In the root of the example package on this page, there is a "DetectionMethodForRemoval.txt". This is the script that we will use for the detection method in the Java Removal deployment. At the very top of the DetectionMethodForRemoval script, change the $IgnoreGUIDs and $ExcludedFolders variables to match the information you retrieved earlier. This should be set similiarly as in the Java Removal Script itself.
```
#Ignore GUIDS (Current Java Versions)
$IgnoreGUIDs = @("{26A24AE4-039D-4CA4-87B4-2F64180112F0}", "{26A24AE4-039D-4CA4-87B4-2F32180112F0}")
 
#Folders to ignore
$ExcludedFolders = @("jre1.8.0_112")
```
#### Putting it all together in SCCM
##### Pre-SCCM
Move the entire package from the working directory into your SCCM package share. This will be different for all environments, but it will be the directory where most of your other source files are saved for other deployments.
##### Create the Install Application Packages
1. Create a new Application in SCCM.
2. Use custom settings and set the deployment type to script.
3. Ensure you point the source to the "Extracted\x86" folder in the folder structure that was uploaded.
4. Set the install command to the "Install.bat" file. You do not need to specify an uninstall command.
5. Set the detection method to MSI installer, and input the GUID for the 32-bit version of Java. (Including curly braces)
6. Save the Application deployment. Repeat from step one and create another package for the 64-bit version of Java, pointing it's source to the "Extracted\x64" folder instead.
##### Create the Uninstall Application Package
1. Create a new Application in SCCM
2. Use custom settings and set the deployment type to script
3. Set the source to the "Extracted\JavaRemoval" folder.
4. Set the install and uninstall command to the "JavaRemoval.bat" file
5. Set your detection method to script, and ensure that the script type is set to "PowerShell" then copy the contents of the "DetectionMethodForRemoval.txt" and paste that into the text box.
6. Save the new Application Package
#### Deploying your packages
1. Deploy your 32-bit and 64-bit Java Installation packages at the same time.
2. Give it a week or two to propagate through your network.
3. Once you have reached your threshold of machines with the new Java, deploy the Java removal script. Ensure that the deployment is set to "Uninstall" and deploy it so that it will run during maintenance windows, otherwise, your users may be impacted by the script automatically closing their browsers.
