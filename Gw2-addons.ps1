<#
.Synopsis
   Downloads addons for Guild Wars 2
.DESCRIPTION
   Fancy long description - TBD at 1.0
.EXAMPLE
    Nothing special yet, a lot todo, so no fancy arguments. Also it might get interactive...
    .\gw2-addons.ps1

.NOTES
    Author: Daniel Rothgänger, mail@redicio.us
    Version: 0.2
    Date: 2020-04-28

    Todos: 
     - Setup Gitlab project
     - self-update
     - configuration file for preferences + Smart chainload with custom configs
     - outsource $addons[]
    
     nice to have features:
     - caching for downloads
     - parallel downloading for all addons
    
     Known limitations: 
     - assumes that addons are a single file download (one file or zipped)

.FUNCTIONALITY
   TBD at 1.0

#>

[cmdletbinding()]
Param()

Write-Verbose "Verbose output enabled"

#statics
$TempDir = ($env:TEMP) + "\GW2Addons\"


# functions
function Set-ShortCutOnDesktop {
    param(
        [string]$ShortCutName,
        [string]$Exe
    )
    $ShortCutPath = "$Home\Desktop\" + $ShortCutName + ".lnk"
    $WshShell = New-Object -comObject WScript.Shell -erroraction stop
    $Shortcut = $WshShell.CreateShortcut($ShortCutPath)
    $Shortcut.TargetPath = $Exe
    $Shortcut.WorkingDirectory = split-path ($Exe)
    $Shortcut.Save()
}



# check in correct dir - why not search for gw2 install folder? because GW2 is quite flexible about the installation dir - you could have multiple copies and run it from everywhere and the registry contains only the one that has used the official installer for uninstallation
if (!((test-path ".\bin64") -and (test-path "Gw2-64.exe"))) {
    write-warning "You are not running this from an actual Guild Wars 2 Directory!"
    pause
    return
}

# check game runnning
if ((get-process *gw* | ? { $_.Path -eq (get-item "GW2-64.exe").fullname }).count -gt 0) {
    write-warning "The game is running! You need to close the game first!"
    pause
    return
}

$DateStart = get-date
write-host "Welcome to gw2 addon installer!`r`ncheck https://gitlab.deep-space-nomads.com/Redicious/guild-wars-2-addons-manager for updates!`r`n`r`nSelect one of the following options:"

$packages = @(
    [PSCustomObject]@{ PID = "1"; AIDs = @(1..4); msg = "Install/Update everything (Taco+POIs, Radial Mount and ArcDPS)" },
    [PSCustomObject]@{ PID = "2"; AIDs = @(5); msg = "Install/Update ArcDPS (+Uninstalling Radial Mount if present, or other addons that use d3d9.dll)" },
    [PSCustomObject]@{ PID = "3"; AIDs = @(6); msg = "Install/Update RadialMount (+Uninstalling ArcDPS if present, or any other addons that use d3d9.dll)" },
    [PSCustomObject]@{ PID = "4"; AIDs = @(1, 4); msg = "Install/Update ArcDPS and RadialMount (+Uninstalling any other addons that use d3d9.dll if present)" },
    [PSCustomObject]@{ PID = "5"; AIDs = @(2); msg = "Install/Update Taco" },
    [PSCustomObject]@{ PID = "6"; AIDs = @(2, 3); msg = "Install/Update Taco+POIs" },
    #[PSCustomObject]@{ PID="U"; AIDs=@(); msg="Update this script" },
    [PSCustomObject]@{ PID = "Q"; AIDs = @(); msg = "Do nothing and quit" }
)

$packages | % { write-host "[$($_.PID)] $($_.msg)" }
write-host "Choose wisely like wesly"

write-host ($msg -join "`r`n")


do {
    $PackageID = Read-Host -Prompt 'Enter your choice'
} While ($PackageID -notin $packages.PID)

if ($PackageID -eq "Q") {
    return "bye!"
}

$AIDs = ($packages | ? { $_.PID -eq $PackageID }).AIDs
$packages = $null

# actual downloading\unzipping\copying 
try {

    # take care of temp dir: clear or create
    if (test-path $TempDir) {
        gci $TempDir | remove-item -recurse -force -erroraction stop | out-null
    }
    else {
        new-item -type Directory -Path $TempDir -force -erroraction stop | out-null   
    }

    $Addons = @(
        @{
            ID       = 1;
            Name     = "Radial Mount"; 
            DL       = ("https://github.com" + (((Invoke-WebRequest https://github.com/Friendly0Fire/GW2Radial/releases/latest -UseBasicParsing).content -split "`r`n" | select-string -pattern "`"\/.*GW2Radial\.zip`"" -AllMatches).matches.groups[0].value -replace '"'));
            Type     = "Zip"
            CopyJobs = @(@{from = "d3d9.dll"; to = "bin64\d3d9_chainload.dll" })
        },
        @{
            ID        = 2;
            Name      = "TacO";
            DL        = (((Invoke-WebRequest http://www.gw2taco.com/ -UseBasicParsing).content | select-string -pattern "<a href='(.*)'.*\s\d{3}\.\d{4}r" -AllMatches).matches[0].groups[1].value -replace "dl=0$", "dl=1");
            Type      = "Zip";
            CopyJobs  = @(@{from = ""; to = ""; recurse = $true });
            ShortCuts = @(@{exe = ".\TacO\GW2TacO.exe"; name = "GW2TacO" })
        },
        @{
            ID       = 3;
            Name     = "TacO-poi-tekkitworkshop";
            DL       = "http://tekkitsworkshop.net/index.php/gw2-taco/download/send/2-taco-marker-packs/32-all-in-one"
            Type     = "directWName";
            FileName = "tw_ALL_IN_ONE.taco"
            CopyJobs = @(@{from = "tw_ALL_IN_ONE.taco"; to = "TacO\POIs\tw_ALL_IN_ONE.taco" });
            Comment  = "Great POIs for Super adventure box, rich nodes and gardens!"
        },
        @{
            ID       = 4;
            Name     = "Arc DPS";
            DL       = "https://www.deltaconnected.com/arcdps/x64/d3d9.dll";
            Type     = "directWName"
            FileName = "d3d9.dll"
            CopyJobs = @(@{from = "d3d9.dll"; to = "bin64\d3d9.dll" })
        },
        @{
            ID         = 5;
            Name       = "Arc DPS";
            DL         = "https://www.deltaconnected.com/arcdps/x64/d3d9.dll";
            Type       = "directWName"
            FileName   = "d3d9.dll"
            CopyJobs   = @(@{from = "d3d9.dll"; to = "bin64\d3d9.dll" })
            DeleteJobs = @("bin64\d3d9_chainload.dll")
        },
        @{
            ID         = 6;
            Name       = "Radial Mount"; 
            DL         = ("https://github.com" + (((Invoke-WebRequest https://github.com/Friendly0Fire/GW2Radial/releases/latest -UseBasicParsing).content -split "`r`n" | select-string -pattern "`"\/.*GW2Radial\.zip`"" -AllMatches).matches.groups[0].value -replace '"'));
            Type       = "Zip"
            CopyJobs   = @(@{from = "d3d9.dll"; to = "bin64\d3d9.dll" })
            DeleteJobs = @("bin64\d3d9_chainload.dll")
        } 
    ) | ? { $_.ID -in $AIDs }

    foreach ($addon in ($addons | ? { $_.DL -ne $null })) {
        # get target for download
        $TargetDLDir = $TempDir + $addon.name
        switch ($addon.type) {
            "direct" { $TargetDL = $TargetDLDir + "\" }
            "directWName" { $TargetDL = $TargetDLDir + "\" + $addon.FileName }
            "Zip" { $TargetDL = $TargetDLDir + "." + $addon.type }
            default { Throw "Internal Error, unknown type $($addon.type)" }
        }

        if (!(test-path ($TempDir + $addon.name))) {
            new-item -type directory -path $TargetDLDir -force -erroraction stop | out-null
        }

        # Downloading remote files
        "$($addon.dl) -> $($TargetDL)"
        write-verbose "Invoke-WebRequest -uri $($addon.dl) -outfile $($TargetDL) -usebasicparsing -erroraction stop"
        Invoke-WebRequest -uri $addon.dl -outfile $TargetDL -usebasicparsing -erroraction stop
        start-sleep -milliseconds 100 # I/O is sometimes weird, too lazy to check for handles
        if (!(test-path $TargetDL)) {
            Throw "The download for addon $($addon.name) failed - maybe the payload was null"
        }

        if ($TargetDL -match '\.zip$') {
            Expand-Archive -Path $TargetDL -DestinationPath ($TempDir + $addon.name + "\") -erroraction stop
            start-sleep -milliseconds 100 # I/O is still sometimes weird, still too lazy to check for handles
        }
        
        # Apply downloaded files for actual target
        foreach ($CopyJob in $addon.CopyJobs) {
            "$($TempDir+$addon.name)\$($CopyJob.from) -> $(".\"+$CopyJob.to)"
            write-verbose "copy-item -path $($TempDir+$addon.name+'\'+$CopyJob.from) -destination $('.\'+$CopyJob.to) -recurse:$($CopyJob.recurse) -erroraction stop -force"
            copy-item -path ($TempDir + $addon.name + '\' + $CopyJob.from) -destination ('.\' + $CopyJob.to) -recurse:$CopyJob.recurse -erroraction stop -force
        }

        # create application shortcuts on desktop
        foreach ($ShortCut in $addon.ShortCuts) {
            $Exe = (get-item -path ($ShortCut.exe) -erroraction stop).FullName
            Set-ShortCutOnDesktop -exe $exe -ShortCutName $ShortCut.name
        }

        # cleanup downloaded file
        get-item $TargetDL | remove-item -erroraction silentlycontinue

        # delete jobs
        foreach ($DeleteJob in $addon.DeleteJobs) {
            if(test-path -path $DeleteJob)
            {
                "Deleting $(".\"+$DeleteJob)"
                remove-item -path ('.\'+$DeleteJob) -erroraction stop -force
            }
        }
    }
}
catch {
    Write-warning "oops, something did go wrong. Maybe this will help:"
    Throw $_
}
finally {
    remove-item $TempDir -Recurse -Force
    "Execution took $((new-timespan -start $DateStart).Totalseconds) seconds"
}
