# Printing menu and all related stuff

function Invoke-Menu {

    do {
        write-host "`r`n`r`n"
        if ($Host.UI.RawUI.WindowSize.Width -ge 118) {
            Write-Host "Welcome to
  __________      __________    _____       .___  .___                                                               
 /  _____/  \    /  \_____  \  /  _  \    __| _/__| _/____   ____   _____ _____    ____ _____     ____   ___________ 
/   \  __\   \/\/   //  ____/ /  /_\  \  / __ |/ __ |/  _ \ /    \ /     \\__  \  /    \\__  \   / ___\_/ __ \_  __ \
\    \_\  \        //       \/    |    \/ /_/ / /_/ (  <_> )   |  \  Y Y  \/ __ \|   |  \/ __ \_/ /_/  >  ___/|  | \/
 \______  /\__/\  / \_______ \____|__  /\____ \____ |\____/|___|  /__|_|  (____  /___|  (____  /\___  / \___  >__|   
        \/      \/          \/       \/      \/    \/           \/      \/     \/     \/     \//_____/      \/       
    by Redicious           https://gitlab.deep-space-nomads.com/Redicious/guild-wars-2-addons-manager/`r`n                              v$Version`r`n" -BackgroundColor Black -ForegroundColor Red 
        }
        else {
            Write-Host "Welcome to
  __________      __________  
 /  _____/  \    /  \_____  \ 
/   \  __\   \/\/   //  ____/ 
\    \_\  \        //       \  Addonmanager
 \______  /\__/\  / \_______ \    by Redicious
        \/      \/          \/       v$Version
 https://gitlab.deep-space-nomads.com/Redicious/guild-wars-2-addons-manager/`r`n" -BackgroundColor Black -ForegroundColor Red 
        } 
        
        $JA = Get-MyAddonsJoined -UpdateMeta

        $OptionIndex = ($JA | select-object id -ExpandProperty ID | sort-object ID -Descending | select -first 1) + 1

        $Actions = @()

        # foreach ($Setting in @('Autologin', 'WindowMode')) {
        #     if ($GameSettings -and $GameSettings.$Setting) {
        #         $Actions += [PSCustomObject]@{ ID = $null; Text = "Disable GW2 $Setting (is enabled)"; Function = "Disable-GW2Setting -Name '$Setting'" }
        #     }
        #     else {
        #         $Actions += [PSCustomObject]@{ ID = $null; Text = "Enable GW2 $Setting"; Function = "Enable-GW2Setting -Name '$Setting'" }
        #     }
        # }

        @(
            [PSCustomObject]@{ ID = $null; Text = "Update/install all enabled=1 and uninstall enabled=0"; Function = "Set-Addon" }
            #[PSCustomObject]@{ ID = $null; Text = "Update/install one addon..."; Function = "Set-Addon -select" }
        ) | % { $Actions += $_ }

        if (($JA | ? { $_.id -eq 2 }).InstalledVersion -notin '', $null) {
            @(
                [PSCustomObject]@{ ID = "T"; Text = "Run Taco"; Function = "Invoke-Taco" },
                [PSCustomObject]@{ ID = "TR"; Text = "Run Taco & GW2"; Function = "Invoke-Taco; Invoke-GW2" }
            )  | % { $Actions += $_ }
        }
        else {
            @(
                [PSCustomObject]@{ ID = "-"; Text = "Run Taco (Not installed)"; Function = "" },
                [PSCustomObject]@{ ID = "-"; Text = "Run Taco (Not installed) & GW2"; Function = "" }
            )  | % { $Actions += $_ }
        }

        @(
            [PSCustomObject]@{ ID = "A"; Text = "Update/Install/Uninstall + Run GW2 + Quit (like ""-auto"" parameter, ""H"" for more info)"; Function = "Invoke-AutomaticStart" },
            [PSCustomObject]@{ ID = "R"; Text = "Run GW2"; Function = "Invoke-GW2" },
            [PSCustomObject]@{ ID = "F"; Text = "Run GW2 Repair (takes a while)"; Function = "Invoke-GW2 -Repair" },
            [PSCustomObject]@{ ID = "D"; Text = "Run GW2 Diagnose (takes a while)"; Function = "Invoke-GW2 -Diag" },
            [PSCustomObject]@{ ID = "C"; Text = "Change GW2 Installpath (Currently ""$GW2Dir"")"; Function = '$GW2Dir = (Get-GW2Dir -force)' },
            [PSCustomObject]@{ ID = "H"; Text = "Display help page, addon information and limitations of this tool"; Function = "Write-HelpPage" },
            [PSCustomObject]@{ ID = "N"; Text = "Nothing and Refresh the menu, I changed my window size!"; Function = "" },
            [PSCustomObject]@{ ID = "S"; Text = "Create Desktop Shortcut"; Function = "CreateSortcut" },
            [PSCustomObject]@{ ID = "SA"; Text = "Create Desktop Shortcut with Autostart"; Function = "CreateSortcut -auto" },
            #[PSCustomObject]@{ ID = "Res"; Text = "Reset addonmanager and exit"; Function = "" }
            [PSCustomObject]@{ ID = "Q"; Text = "Quit"; Function = "Quit()" }
        ) | % { $Actions += $_ }



        $Actions | ? { $null -eq $_.id } | % { $_.id = $OptionIndex; $OptionIndex++ }

        write-host "Addons" -ForegroundColor $MenuHeadColor
        $JA | select-object @{Name = 'Toggle' ; Expression = { if ($_.ID -ne "-") { "[" + $_.ID + "]" } else { " " + $_.ID + " " } } }, name, enabled, state, InstalledVersion, UpstreamVersion | Format-Table -AutoSize

        write-host "Actions" -ForegroundColor $MenuHeadColor
        $Actions | select-object @{Name = 'Select' ; Expression = { if ($_.ID -ne "-") { "[" + $_.ID + "]" } else { " " + $_.ID + " " } } }, Text | Format-Table -AutoSize -HideTableHeaders

        write-host "You can select an action by entering the characters within the []. For addons you toggle the ""enabled"" flag. `r`nIf you change the Addons enabled flag, you need to run the Update/install action."
        write-host "`r`nAll Addons are recommended - but leave out Arc DPS if you don't want the competition... trust me, there will be."
        write-host "`r`nYou can type multiple actions at once with a comma-delimiter, e.g. ""1,2,4,7,R""."
        if ($Actions.ID -contains "-") {
            write-host "`r`nOptions with a ""-"" are disabled as they are not available for you currently."
        }
        write-host "`r`nChoose wisely, like Wesly"

        # Adding addon toggle to actions, AFTER they are displayed, as we don't want to show them twice.
        foreach ($J in $JA) {
            Write-Debug "Adding addon to actions: $($J.ID) $($J.name): ""Toggle-Addon -id $($J.id)"" "
            $Actions += [PSCustomObject]@{ ID = $J.ID; Text = "Toggle enabled flag of Addon ""$($J.name)"""; Function = "Toggle-Addon -id $($J.id)" }
        }

        $Options = $Actions.ID | where-object { $_ -notin $null, '-', '' } | Sort-Object -Unique
        $Option = (ask -Quest "Enter your choice" -ValidOptions $Options -Delimiter ",")

        foreach ($O in $Option) {
            if ($O -eq "Q") {
                write-host "bye!"
                Return
            }
            if ($O -eq "N") {
                # Nothing
            }
            if ($O -eq "Res") {
                Remove-Item -path $MyAddonsFile
                Return
            }
            else {
                $IEX = ($Actions | where-object { $_.ID -eq $O }).Function
                iex $IEX    
            }
        }
    } while (1) # :-P
}

function Invoke-AutomaticStart {
    Set-Addon  
    if (((Get-MyAddonsJoined -UpdateMeta) | ? { $_.id -eq 2 }).InstalledVersion -notin '', $null) {
        Invoke-Taco 
    }
    Invoke-GW2
}

function Invoke-TacO {
    write-host "starting Taco $TacOExec"
    if (get-process | ? { $_.path -eq $TacOExec }) {
        Write-Warning "Taco already running!"
    }
    else {
        Start-Process -FilePath $TacOExec -WorkingDirectory $TacoDir    
    }
}

function Invoke-GW2 {
    param([switch]$Repair, [switch]$Diag)
    if (get-process | ? { $_.path -eq $GW2Exec }) {
        Write-Warning "GW2 already running!"
    }
    else {
        if ($repair) {
            write-host "Executing GW2 ($GW2Exec) Repair..."
            Start-Process -FilePath $GW2Exec -wait -ArgumentList "-repair" -WorkingDirectory $GW2Dir
        }
        elseif ($Diag) {
            write-host "Executing GW2 ($GW2Exec) Diag..."
            Start-Process -FilePath $GW2Exec -wait -ArgumentList "-diag" -WorkingDirectory $GW2Dir
        }
        else {
            write-host "starting GW2 ($GW2Exec)..."
            Start-Process -FilePath $GW2Exec -wait:$KeepOpen -WorkingDirectory $GW2Dir  
        }
    }       
}