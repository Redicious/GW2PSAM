# functions regarding addons install/uninstall etc
function Set-Addon {
    param(
        [Switch] $Select
    )
    Save-MyAddon

    $Addons = Get-MyAddonsJoined -UpdateMeta
    
    if ($Select) {
        $addons = $addons | ? { $_.id -in $IDs }
    }

    # Define addons we do stuff with
    $UninstallAddons = @()
    $InstallAddons = @()

    $Addons | ? { $_.enabled -eq $false -and $_.InstalledVersion -notin '', $null } | %{ $UninstallAddons += $_ }
    $Addons | ? { $_.enabled -eq $true -and ($_.InstalledVersion -in '', $null -or $_.InstalledVersion -ne $_.UpstreamVersion) } | %{ $InstallAddons += $_ }

    $AffectedIDs = @()
    $UninstallAddons.ID | %{ $AffectedIDs += $_ }
    $InstallAddons.ID | %{ $AffectedIDs += $_ }
    $AffectedIDs = $AffectedIDs | ?{ $_ -notin '',0,$null }| Sort-Object -Unique



    # Find Addons that need to be reinstalled, due to above changes
    $ReinstallAddons = $Addons | Where-Object { (Test-CrossContains -a $_.Steps.IfIds -b $AffectedIDs) -or  (Test-CrossContains -a $_.Steps.IfNotIds -b $AffectedIDs) } 
    $ReinstallAddons | % { $UninstallAddons += $_; $InstallAddons += $_   }

    write-debug "those addons need reinstallement (affectedIDs=$($AffectedIDs -join ', ')): $($ReinstallAddons.Id -join ', ')"

    # Check for running application
    $UninstallAddons.RequiresAppClosed | Sort-Object -Unique | %{ RequireAppClosed -Path $_ -ErrorAction STOP } | %{ if($_ -contains "cancel") { return } else { $_ }}
    $InstallAddons.RequiresAppClosed | Sort-Object -Unique | %{ RequireAppClosed -Path $_ -ErrorAction STOP } | %{ if($_ -contains "cancel") { return } else { $_ }}
    
    # Find StepDepth 
    $MaxDepth = ((Get-MyAddonsJoined).Steps.Level | measure-object -max).Maximum
    write-debug "found maxdepth $Maxdepth"
    # Uninstall
    if ($null -ne $UninstallAddons -and $UninstallAddons.Count -gt 0) {
        write-debug "uninstalling $($UninstallAddons.count) addons..."
        $IEX = '$UninstallAddons '#Uninstall-addon
        for ($i = $MaxDepth; $i -ge 0; $i--) {
            write-debug $i
            $IEX = $IEX + '| UnDoAddonStep -level '+$i+' -passthru ' # | %{ Update-MyAddonVersion -id $_.id -uninstalled }'
        }
        $IEX = $IEX + '| %{ Update-MyAddonVersion -id $_.id -uninstalled}'
        write-debug "$IEX"
        Invoke-Expression $IEX
        write-debug "done"
        Save-MyAddon
    }
    else {
        Write-debug "no addons to uninstall"
    }
    # Install
    if ($null -ne $installAddons -and $installAddons.Count -gt 0) {
        write-debug "installing $($InstallAddons.count) addons..."
        $IEX = '$installAddons '#Uninstall-addon
        for ($i = 1; $i -le $MaxDepth; $i++) {
            $IEX = $IEX + "| DoAddonStep -level $i -passthru"
        }
        write-debug "$IEX"
        $IEX = $IEX + '| DoAddonCleanup -passthru | %{ Update-MyAddonVersion -id $_.id }'
        Invoke-Expression $IEX
        write-debug "done"
        Save-MyAddon
    }
    else {
        Write-debug "no addons to install"
    }
    if(test-path $addontemp)
    {
        Get-Item -path $AddonTemp | remove-item -Recurse -WhatIf
    }
    Save-MyAddon
}

function DoAddonStep {
    param (
        [Parameter(ValueFromPipeline)]$Addon,
        [ValidateNotNullOrEmpty()][int] $level,
        [switch] $PassThru
    )

    Begin {
        
    }

    Process {
        # find the correct step
        $EnabledAddonIDs = (Get-MyAddon | ? { $_.Enabled -eq "True"}).ID | %{ [string]$_ }
        $Step = $Addon.Steps | Where-Object { $_.level -eq [string]$level }
        write-debug "Found $($step.count) Steps, now filtering by conditions..."
        write-debug "EAIDs: $($EnabledAddonIDs -join ',')"
        $Step = $Step | Where-Object { ($null -eq $_.IfNotIDs -or !(Test-CrossContains -a ($_.IfNotIDs -split ',') -b $EnabledAddonIDs)) -and ($null -eq $_.IfIDs -or (Test-CrossContains -a ($_.IfIDs -split ',') -b $EnabledAddonIDs)) } 
        write-debug "$($step.count) Steps survived conditions"

        if ($null -ne $step) {
            if ($Step.Count -gt 1) {
                Throw "Internal Error: couldn't identify step: multiple matches"
            }
            elseif ($Step.Count -eq 1) {
                $ErrCount = 0
                $MaxRetries = 3
                $done = $false
                do {
                    start-sleep -seconds ($ErrCount * 2)
                    try {
                        write-host "executing step action=$($step.action) level=$Level for addon $($addon.name)..." -ForegroundColor $ForegroundcolorStatusInformation
                        switch ($step.action) {
                            "download" { DownloadFile -from $Step.from -to $Step.to -ErrorAction stop }
                            "Unzip" { Expand-Archive -Path $step.from -DestinationPath $step.to -ErrorAction stop -force }
                            "copy" { Copy-Item -path $Step.from -destination $Step.to -force -ErrorAction stop }
                            "move" { move-Item -path $Step.from -destination $Step.to -force -ErrorAction stop }
                            default { Throw "Internal Error: unknown action type $($Step.action)" }
                        }
                        $done = $true
                    }
                    Catch {
                        $ErrCount++;
                        if ($ErrCount -ge $MaxRetries) {
                            Throw "Maximum retries exceeded on ""$($step.action)"" from $($step.from) to $($step.to) with: $_"
                        }
                    }
                } while (!$done -and ($ErrCount -le $MaxRetries))
            }
        }
        else {
            write-debug "nothing to do ($($addon.name): level=$level)"
        }

        if ($PassThru) {
            $Addon
        }
    }
}

function UnDoAddonStep {
    param (
        [Parameter(ValueFromPipeline)]$Addon,
        [ValidateNotNullOrEmpty()][int] $level,
        [switch] $PassThru
    )

    Begin {
        $EnabledAddonIDs = (Get-MyAddon | ? { $_.Enabled }).ID
    }

    Process {
        # find the correct step
        $Steps = $Addon.Steps | Where-Object { $_.level -eq $level }

        if ($null -ne $steps) {
            foreach($step in $steps)
            {
                write-debug "foreach step ($($Step.action)) in Steps ($($Steps.count))... "
                $ErrCount = 0
                $MaxRetries = 3
                do {
                    $Done = $false
                    start-sleep -seconds ($ErrCount * 2)
                    write-host "executing UNDO step action=$($step.action) level=$($step.Level) for addon $($addon.name)..." -ForegroundColor $ForegroundcolorStatusInformation
                    try {
                        if($step.action -eq "unzip")
                        {
                            Write-warning "Can't perform undo for unzipping $($step.from) to $($step.to) - sorry, but the risk is too high. For now... "
                        }
                        elseif($step.from -match "\*")
                        {
                            Write-warning "Can't perform undo for moving or copying with wildcards  $($step.from) to $($step.to) - sorry for wasting disk space, but the risk is too high. For now... "
                        }
                        else {
                            if(test-path -path $step.to)
                            {
                                write-debug "removing file $($step.to)"
                                Remove-Item -Path $step.to -force -Erroraction stop
                            }
                        }
                        $Done = $true
                    }
                    Catch {
                        write-debug "EXCEPTION: $_"
                        $ErrCount++;
                        if ($ErrCount -ge $MaxRetries) {
                            Throw "Maximum retries exceeded on ""$($step.action)"" from $($step.from) to $($step.to)"
                        }
                    }
                } while (!$Done -and $ErrCount -le $MaxRetries)
            }
        }
        else {
            write-debug "No UNDO step at level=$($Level) for addon $($addon.name)"
        }

        if ($PassThru) {
            $Addon
        }
    }
}

function DownloadFile {
    param (
        [ValidateNotNullOrEmpty()][string] $from,
        [ValidateNotNullOrEmpty()][string] $to
    )
    if(!(test-path (split-path $to)))
    {
        new-item -type Directory -path (split-path $to) -force
    }
    write-host "Downloading $($from) -> $($to)" -ForegroundColor $ForegroundcolorStatusInformation
    write-verbose "Invoke-WebRequest -uri $($from) -outfile $($to) -usebasicparsing -erroraction stop"
    Invoke-WebRequest -uri $from -outfile $to -usebasicparsing -erroraction stop
    start-sleep -milliseconds 100 # I/O (especially with antivirus) is sometimes weird, too lazy to check for handles - YIELD!
    if (!(test-path $addon.DownloadTo)) {
        Throw "The download for from $from failed - maybe the payload was null?"
    }     
}


function DoAddonCleanup {
    param (
        [Parameter(ValueFromPipeline)]$Addon,
        [ValidateNotNullOrEmpty()][int] $level,
        [switch] $PassThru
    )
    Process {
        # find the correct step
        $Steps = $Addon.Steps | Where-object { $_.cleanup -eq "1" }
        if($level)
        {
            $Steps = $Steps | Where-Object { $_.level -eq $level }
        }
        
        if ($null -ne $steps) {
            foreach($step in $steps)
            {
                $ErrCount = 0
                $MaxRetries = 3
                do {
                    start-sleep -seconds ($ErrCount * 2)
                    write-host "executing cleanup for step action=$($step.action) level=$($step.Level) for addon $($addon.name)..." -ForegroundColor $ForegroundcolorStatusInformation
                    try {
                        if($step.action -eq "unzip")
                        {
                            Write-warning "Can't perform undo for unzipping $($step.from) to $($step.to) - sorry for wasting disk space, but the risk is too high. For now..."
                        }
                        elseif($step.from -match "\*")
                        {
                            Write-warning "Can't perform undo for moving or copying with wildcards  $($step.from) to $($step.to) - sorry for wasting disk space, but the risk is too high. For now... "
                        }
                        else {
                            if(test-path -path $step.to)
                            {
                                Remove-Item -Path $step.to -force -Erroraction stop
                            }
                        }
                    }
                    Catch {
                        $ErrCount++;
                        if ($ErrCount -ge $MaxRetries) {
                            Throw "Maximum retries exceeded on ""$($step.action)"" from $($step.from) to $($step.to)"
                        }
                    }
                } while ($ErrCount -le $MaxRetries)
            }
        }

        if ($PassThru) {
            $Addon
        }
    }
}

function RequireAppClosed {
    Param($Path)
    
    $Options = @(
        [PSCustomObject]@{ OptionID = "Y"; Text = "Yes, please check again" },
        [PSCustomObject]@{ OptionID = "N"; Text = "No, please close it for me and I undestand you wont be gentle and I accept any dataloss because I'm a badass 8-)" },
        [PSCustomObject]@{ OptionID = "C"; Text = "Cancel the update" }
    )

    $Count = 0
    $mod = ""
    while((get-process | Where-Object { $_.Path -eq $Path}).count -gt 0)
    {
        write-debug "RequireAppClosed Path=$Path | count=$count"
        if ($Count -eq 1) {
            $mod = " still"
        }
        elseif ($Count -eq 2) {
            $mod = $mod.ToUpper()
        }
        elseif ($Count -ge 3) {
            $mod = $mod + "!"
        }
        if($Count -ge 2)
        {
            Write-Host "
            _________            .__                    .__         _________._.
           /   _____/ ___________|__| ____  __ __  _____|  | ___.__.\_____   \ |
           \_____  \_/ __ \_  __ \  |/  _ \|  |  \/  ___/  |<   |  |   /   __/ |
           /        \  ___/|  | \/  (  <_> )  |  /\___ \|  |_\___  |  |   |   \|
          /_______  /\___  >__|  |__|\____/|____//____  >____/ ____|  |___|   __
                  \/     \/                           \/     \/       <___>   \/`r`n" -BackgroundColor Black -ForegroundColor Red 
        }

        Write-Warning -Message "The App $(Split-Path $Path -leaf) is$mod running (from $Path) and needs to be closed before we can continue. Please tell me how to proceed. Ignoring is not an option..."
        $Options | select-object @{Name = 'OptionID' ; Expression = {  "[" + $_.OptionID + "]" } }, Text | Format-Table -AutoSize -HideTableHeaders
        $Option = (ask -Quest "What do you say? Did you close it?" -ValidOptions $Options.OptionID -Delimiter ",")

        if($Option -eq "N")
        {
            get-process | Where-Object { $_.Path -eq $Path} | stop-process
        }
        elseif ($option -eq "C") {
            Return "Cancel"
        }
        $Count++;
    }
}
