# general functions
function Copy-Object
{
    param ( $InputObject )
    $OutputObject = New-Object PsObject
    $InputObject.psobject.properties | foreach-object {
        $OutputObject | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value
    }
    return $OutputObject
}

function Test-CrossContains
{
    Param($a, $b)
    foreach($an in $a)
    {
        if($b -contains $an)
        {
            return $true
        }
    }
    foreach($bn in $b)
    {
        if($a -contains $bn)
        {
            return $true
        }
    }
    return $false    
}

function Get-GW2Dir {
    param([switch]$force)
    # Already selected a folder
    if ((test-path -path $GW2DirFile -erroraction stop) -and ((Get-Content -path $GW2DirFile -erroraction stop).trim() -ne '')) {
        $Guess = (Get-Content -path $GW2DirFile).trim()
        if(!$force)
        {
            return ($guess.TrimEnd('\')+'\')
        }
    }     
    else {
        $Guess = Split-Path ((Get-ChildItem HKCU:\\system\GameConfigStore\Children\* | Get-ItemProperty).MatchedExeFullPath | ? { $_ -match 'gw2-64.exe$' } | select -first 1).trim()
    }

    $Result = ask -Quest "Is this the location you have Guild Wars 2 installed? `r`n$Guess`r`n [Y]es/[N]o/[C]ancel" -ValidOptions @("Y", "N", "C")
    if ($Result -eq "Y") {
        $guess | set-content -path $GW2DirFile
        Return ($Guess.TrimEnd('\')+'\')
        
    }
    elseif ($Result -eq "C") {
        Return ($Guess.TrimEnd('\')+'\')
    }
    elseif ($Result -eq "N") {
        $ResultN=  (ask -Quest "Please enter the directory manually (Rightclick this window to paste your clipboard)" -ValidateNotNullOrEmpty)
        $ResultN | set-content -path $GW2DirFile
        return ($ResultN.TrimEnd('\')+'\')
        # Todo, shiny folder selector
    }

}

function ask {
    param(
        [ValidateNotNullOrEmpty()]$Quest,
        $Preselect,
        $ValidOptions,
        [string] $Delimiter,
        [Switch]$ValidateNotNullOrEmpty
    )

    Write-Debug "ask( QUEST=$Quest | PRESELECT=$Preselect | VALIDOPTIONS=$($Validoptions -join ',') | DELIMITER=$DELIMITER | VALIDATENOTNULLOREMPTY=$ValidateNotNullOrEmpty"

    if($Delimiter)
    {
        $RXP = "^("+($ValidOptions -join '|')+")"+"("+$Delimiter+"("+($ValidOptions -join '|')+"))*$"
        Write-Debug "Regular Expression for input validation: $RXP"
    }

    do {
        $Result = (Read-Host -Prompt $Quest).trim()
        if ($Preselect -and $Result -in '', $null) {
            Return $Preselect
        }
        elseif (!$Delimiter -and ($ValidOptions -and $Result -notin $ValidOptions)) {
            Write-Warning "Your selection is invalid..."
        }
        elseif ($Delimiter -and $ValidOptions -and ($Result -notmatch $RXP)) {
            Write-Warning "Your selection is invalid..."
        }
        elseif ($ValidateNotNullOrEmpty -and $Result -in '', $null) {
            Write-Warning "You have to answer something... or press CTRL+C to abort the script."
        }
        else {
            if($Delimiter)
            {
                Return ($Result -split ",")
            }
            else {
                Return $Result    
            }
            
        }           
    } While (1) # yeah, bad style. Judge me
}