param(
    [switch]$NoExe,
    [switch]$RunAfterCompilation    
    )
# for packaging executable files

# push location, so pathing is easier
Push-Location ($MyInvocation.MyCommand.Path | split-path) -erroraction STOP

# install ps2exe, since an exe is easier to use
if (!$NoExe) {
    if (Get-Module -ListAvailable -Name Ps2exe) {
        # maybe add an update-module here... thinking... please wait
    } 
    else {
        try{
            Install-Module ps2exe
        }
        catch
        {
            Write-Warning "You need the powershell module ""ps2exe"" to compile an exe. `r`nOnly the script will be compiled.`r`nIf you want to create the exe you need to install the module (probably as administrator).`r`nYou can install the module with ""Install-Module ps2exe""."
            $NoExe = $True
        }
        Import-Module ps2exe
    }
}

# add the source files to an array
try {
    $Result = @()
    $Result += get-content .\head.ps1 -raw -ErrorAction STOP
    $Result += '# settings.ps1'
    $Result += get-content .\settings.ps1 -raw -ErrorAction STOP
    $Result += '# bootstrap.ps1'
    $Result += get-content .\bootstrap.ps1 -raw -ErrorAction STOP
    $Result += '# help.ps1'
    $Result += get-content .\help.ps1 -raw -ErrorAction STOP
    $Result += '# functions.ps1'
    $Result += get-content .\functions.ps1 -raw -ErrorAction STOP
    $Result += '# vars.xml'
    $Result += '$XMLVars = [XML]' + "@'`r`n" + ((get-content .\vars.xml -raw)) + "`r`n'@"
    $Result += '# myaddons.ps1'
    $Result += get-content .\myaddons.ps1 -raw -ErrorAction STOP
    $Result += '# vars.ps1'
    $Result += get-content .\vars.ps1 -raw -ErrorAction STOP
    $Result += '# menu.ps1'
    $Result += get-content .\menu.ps1 -raw -ErrorAction STOP
    $Result += '# addon_functions.ps1'
    $Result += get-content .\addon_functions.ps1 -raw -ErrorAction STOP
    $Result += '# main.ps1'
    $Result += get-content .\main.ps1 -raw -ErrorAction STOP
    $Result += '}' # lazy af :-)

    # Join the source files and write a powershell script
    $Result -join "`r`n" | Set-Content -path ..\Gw2-AddonsManager.ps1 -ErrorAction STOP
    
    # compile an .exe-file
    if (!$NoExe) {
        # Add a call as workaround for the Exe, so it actually starts the file. TODO: Parameters...
        $Result += 'GW2AddonManager -Exe'

        # write it with the added call to a temp file
        $TempFile = [System.IO.Path]::GetTempFileName()
        $Result -join "`r`n" | Set-Content -path $TempFile -ErrorAction STOP
        
        # compile the exe from the temp file
        "Invoke-ps2exe -inputFile $TempFile -outputFile ..\Gw2-AddonsManager.exe"
        test-path $TempFile
        pause
        Invoke-ps2exe -inputFile $TempFile -outputFile ..\Gw2-AddonsManager.exe
    }

    if($RunAfterCompilation)
    {
        ..\Gw2-AddonsManager.ps1
        GW2AddonManager
    }
}
catch {
    Throw $_
}
finally {
    # undo push location
    Pop-Location

    # cleanup temp file
    if ($Tempfile -and (test-path $TempFile)) {
        Remove-item $TempFile 
    }
}
