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
