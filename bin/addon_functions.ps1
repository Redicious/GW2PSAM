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

    $Addons | Where-Object { $_.enabled -eq $false -and $_.InstalledVersion -notin '', $null } | ForEach-Object{ $UninstallAddons += $_ }
    $Addons | Where-Object { $_.enabled -eq $true -and $_.state -ne "Error" -and ($_.InstalledVersion -in '', $null -or $_.InstalledVersion -ne $_.UpstreamVersion) } | ForEach-Object{ $InstallAddons += $_ }

    $AffectedIDs = @()
    $UninstallAddons.ID | ForEach-Object{ $AffectedIDs += $_ }
    $InstallAddons.ID | ForEach-Object{ $AffectedIDs += $_ }
    $AffectedIDs = $AffectedIDs | Where-Object{ $_ -notin '',0,$null }| Sort-Object -Unique



    # Find Addons that need to be reinstalled, due to above changes
    $ReinstallAddons = $Addons | Where-Object { (Test-CrossContains -a $_.Steps.IfIds -b $AffectedIDs) -or  (Test-CrossContains -a $_.Steps.IfNotIds -b $AffectedIDs) } 
    $ReinstallAddons | ForEach-Object { $UninstallAddons += $_; $InstallAddons += $_   }

    mydebug "those addons need reinstallement (affectedIDs=$($AffectedIDs -join ', ')): $($ReinstallAddons.Id -join ', ')"

    # Check for running application
    $UninstallAddons.RequiresAppClosed | Sort-Object -Unique | ForEach-Object{ RequireAppClosed -Path $_ -ErrorAction STOP } | ForEach-Object{ if($_ -contains "cancel") { return } else { $_ }}
    $InstallAddons.RequiresAppClosed | Sort-Object -Unique | ForEach-Object{ RequireAppClosed -Path $_ -ErrorAction STOP } | ForEach-Object{ if($_ -contains "cancel") { return } else { $_ }}
    
    # Find StepDepth 
    $MaxDepth = ((Get-MyAddonsJoined).Steps.Level | measure-object -max).Maximum
    mydebug "found maxdepth $Maxdepth"
    # Uninstall
    if ($null -ne $UninstallAddons -and $UninstallAddons.Count -gt 0) {
        mydebug "uninstalling $($UninstallAddons.count) addons..."
        $IEX = '$UninstallAddons '#Uninstall-addon
        for ($i = $MaxDepth; $i -ge 0; $i--) {
            mydebug $i
            $IEX = $IEX + '| UnDoAddonStep -level '+$i+' -passthru ' # | %{ Update-MyAddonVersion -id $_.id -uninstalled }'
        }
        $IEX = $IEX + '| %{ Update-MyAddonVersion -id $_.id -uninstalled}'
        mydebug "$IEX"
        Invoke-Expression $IEX
        mydebug "done"
        Save-MyAddon
    }
    else {
        mydebug "no addons to uninstall"
    }
    # Install
    if ($null -ne $installAddons -and $installAddons.Count -gt 0) {
        mydebug "installing $($InstallAddons.count) addons..."
        $IEX = '$installAddons '#Uninstall-addon
        for ($i = 1; $i -le $MaxDepth; $i++) {
            $IEX = $IEX + "| DoAddonStep -level $i -passthru"
        }
        mydebug "$IEX"
        $IEX = $IEX + '| DoAddonCleanup -passthru | %{ Update-MyAddonVersion -id $_.id }'
        Invoke-Expression $IEX
        mydebug "done"
        Save-MyAddon
    }
    else {
        mydebug "no addons to install"
    }
    if(test-path $addontemp)
    {
        Get-Item -path $AddonTemp | remove-item -Recurse 
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
        $EnabledAddonIDs = (Get-MyAddon | Where-Object { $_.Enabled -eq "True"}).ID | ForEach-Object{ [string]$_ }
        $Step = $Addon.Steps | Where-Object { $_.level -eq [string]$level }
        mydebug "Found $($step.count) Steps, now filtering by conditions..."
        mydebug "EAIDs: $($EnabledAddonIDs -join ',')"
        $Step = $Step | Where-Object { ($null -eq $_.IfNotIDs -or !(Test-CrossContains -a ($_.IfNotIDs -split ',') -b $EnabledAddonIDs)) -and ($null -eq $_.IfIDs -or (Test-CrossContains -a ($_.IfIDs -split ',') -b $EnabledAddonIDs)) } 
        mydebug "$($step.count) Steps survived conditions"

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
                        $step | get-member | out-string | write-debug
                        $parentTo = split-path $step.to
                        if(!(test-path $parentTo))
                        {
                            new-item -type directory -path $parentTo -force -ErrorAction stop
                        }

                        switch ($step.action) {
                            "download" { DownloadFile -from $Step.from -to $Step.to -ErrorAction stop }
                            "downloadGitHub" { DownloadGitHub -user $step.user -repo $step.repo -version $step.version -file $step.file -to $Step.to -ErrorAction stop }
                            "Unzip" { Expand-Archive -Path $step.from -DestinationPath $step.to -ErrorAction stop -force }
                            "copy" { get-item $step.from -ErrorAction stop | Copy-Item -destination $Step.to -force -ErrorAction stop }
                            "move" { get-item $step.from -ErrorAction stop | move-Item -destination $Step.to -force -ErrorAction stop }
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
            mydebug "nothing to do ($($addon.name): level=$level)"
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
                mydebug "foreach step ($($Step.action)) in Steps ($($Steps.count))... "
                $ErrCount = 0
                $MaxRetries = 3
                do {
                    $Done = $false
                    start-sleep -seconds ($ErrCount * 2)
                    write-host "executing UNDO step action=$($step.action) level=$($step.Level) for addon $($addon.name)..." -ForegroundColor $ForegroundcolorStatusInformation
                    try {
                        if($step.action -eq "unzip")
                        {
                            mydebug "Can't perform undo for unzipping $($step.from) to $($step.to) - sorry, but the risk is too high. For now... "
                        }
                        elseif($step.from -match "\*")
                        {
                            mydebug "Can't perform undo for moving or copying with wildcards  $($step.from) to $($step.to) - sorry for wasting disk space, but the risk is too high. For now... "
                        }
                        else {
                            if(test-path -path $step.to)
                            {
                                mydebug "removing file $($step.to)"
                                Remove-Item -Path $step.to -force -Erroraction stop
                            }
                        }
                        $Done = $true
                    }
                    Catch {
                        mydebug "EXCEPTION: $_"
                        $ErrCount++;
                        if ($ErrCount -ge $MaxRetries) {
                            Throw "Maximum retries exceeded on ""$($step.action)"" from $($step.from) to $($step.to)"
                        }
                    }
                } while (!$Done -and $ErrCount -le $MaxRetries)
            }
        }
        else {
            mydebug "No UNDO step at level=$($Level) for addon $($addon.name)"
        }

        if ($PassThru) {
            $Addon
        }
    }
}

function DownloadGitHub {
    param (
        [ValidateNotNullOrEmpty()][string] $user,
        [ValidateNotNullOrEmpty()][string] $repo,
        [ValidateNotNullOrEmpty()][string] $version = 'latest',
        [ValidateNotNullOrEmpty()][string] $file,
        [ValidateNotNullOrEmpty()][string] $to
    )

    if($Version -eq 'Latest')
    {
        $Version = (((Invoke-webrequest  "https://github.com/$user/$repo/releases/latest/" -usebasicparsing).content | sls -pattern 'releases/expanded_assets/([\S]*)' -allmatches).matches.groups[1]).value
    }
    
    try{
        $Asset = (((Invoke-Webrequest "https://github.com/$user/$repo/releases/expanded_assets/$version" -usebasicparsing).content  | sls -pattern 'href="([\S]*)"' -AllMatches).matches.groups | ?{$_.name -eq 1}).value | ?{ $_ -match $file} 
    }
    catch {
        throw "couldn't get assets from github from ""https://github.com/$user/$repo/releases/expanded_assets/$version"" with: $_ "
    }
    
    if($asset.count -gt 1)
    {
        throw "couldn't get asset from github ""https://github.com/$user/$repo/releases/expanded_assets/$version"" since there are $($asset.count) matches for ""$file"":`r`n $($asset -join "`r`n")"
    }
    
    try{
        DownloadFile -from ('https://github.com'+$asset) -to $to 
    }
    catch {
        Write-host "couldn't download from github from ('https://github.com'+$asset) to $to with: $_"
        throw "couldn't download from github from ('https://github.com'+$asset) to $to with: $_"
    }
    
}

function DownloadFile {
    param (
        [ValidateNotNullOrEmpty()][string] $from,
        [ValidateNotNullOrEmpty()][string] $to,
        [switch]$Stream
    )
    if(!(test-path (split-path $to)))
    {
        new-item -type Directory -path (split-path $to) -force
    }
    write-host "Downloading $($from) -> $($to)" -ForegroundColor $ForegroundcolorStatusInformation
    write-verbose "Invoke-WebRequest -uri $($from) -outfile $($to) -usebasicparsing -erroraction stop"
    try{
        Invoke-WebRequest -uri $from -outfile $to -usebasicparsing -erroraction stop -verbose
    }
    catch 
    {
        Write-Error $_
        pause
        Throw $_
    }
    
    $i = 1
    While(!(test-path $to) -and $i -le 10) 
    {
        start-sleep -milliseconds 100*$i 
        $i++   
    }     
    if(!(test-path $to))
    {
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
        mydebug "RequireAppClosed Path=$Path | count=$count"
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
