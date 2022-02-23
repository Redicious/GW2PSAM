# my addons
#$MyAddonsFile = $AppData + "MyAddons.JSON"
function Get-MyAddon {
    param(
        $id
    )
    CreateAppdata
    if ($null -eq (get-variable -name MyAddons -scope script -ErrorAction SilentlyContinue)) {
        if (test-path -path $MyAddonsFile) {
            write-debug "local setting file exists, reading..."
            $script:MyAddons = (get-content -path $MyAddonsFile -ErrorAction stop) | ConvertFrom-Json 
            foreach ($MyAddon in $MyAddons) {
                Update-MyAddon -id $MyAddon 
            }
        }
        else {
            write-debug "local setting file DOESN'T exists, creating new one"
            $script:MyAddons = @()
        }

        foreach ($Addon in $script:Addons) {
            if (!(Test-MyAddonExists -id $Addon.ID)) {
                Add-MyAddon -id $addon.id
            }
        }
    }
    if ($id) {
        write-debug "Get the selected addon with ID $ID"
        $script:MyAddons | Where-Object { $_.id -in $script:addons.id -and $_.id -eq $id }
        
    }
    else {
        write-debug "Get all addons"
        $script:MyAddons | Where-Object { $_.id -in $script:addons.id }
    }
    
}

function Test-MyAddonExists {
    param($id)
    write-debug "checking if addon with $id exists in settings"
    return ( $null -ne ($script:MyAddons | Where-Object { $_.ID -eq $id })  )
}

function Add-MyAddon( $id ) {
    write-debug "adding addon with id=$($addon.id) (name=$($addon.name)) to local settings"
    $script:MyAddons += [PSCustomObject]@{ id = $id; enabled = $False; InstalledVersion = ''; State = "Not Installed"; }
}

function Update-MyAddon ( $Id ) {
    # Reserved for later changes on the local saved addon object, e.g. new values or adding methods (as we don't want to store methods in the local file)
    # todo, make pipeable and pipe after ConvertFrom-Json
}

function Save-MyAddon {
    $script:MyAddons | convertto-json | set-content -path $MyAddonsFile
}

function Enable-MyAddon {
    param($id)
    write-debug "enabling addon with ID $id"
    Set-MyAddon -id $id -Enabled $True
}

function Disable-MyAddon {
    param($id)
    write-debug "disabling addon with ID $id"
    Set-MyAddon -id $id -Enabled $False
}

function Toggle-Addon {
    param($id)
    if ((Get-MyAddon -id $iD).Enabled -eq 1) {
        Disable-MyAddon -id $id
    }
    else {
        Enable-MyAddon -id $id
    }
}

function Set-MyAddon {
    param ( [ValidateNotNullOrEmpty()][int]$ID, [Bool]$Enabled, [string]$InstalledVersion, [string]$State )
    if (Test-MyAddonExists -id $id) {
        $MyAddon = Get-MyAddon -id $id
        if ($PSBoundParameters.ContainsKey('Enabled')) {
            $myAddon.Enabled = $Enabled
        }
        if ($PSBoundParameters.ContainsKey('InstalledVersion')) {
            $MyAddon.InstalledVersion = $InstalledVersion
        }
        if ($State) {
            $MyAddon.State = $State
        }
        
        Save-MyAddon
    }
    else {
        Throw "Addon with id $ID doesn't exist"
    }
}

function Get-MyAddonsJoined {
    param(
        [int] $id,
        [Switch] $UpdateMeta

    )

    if($UpdateMeta)
    {
        Update-MyAddonMeta
    }

    foreach ($MyAddon in (Get-MyAddon -id $Id)) {
        $MyAddonJoined = (Copy-Object -inputobject $MyAddon)
        $Addon = $script:addons | Where-Object { $_.id -in $MyAddonJoined.id }
        $Addon.psobject.properties | where-object { $_.name -ne "id" } | foreach-object {
            $MyAddonJoined | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value
        }
        $MyAddonJoined        
    }
}

function Update-MyAddonVersion{
    param($id, [switch]$Uninstalled)
    if($Uninstalled)
    {
        write-debug "Addon $id set to uninstalled"
        Set-MyAddon -id $id -InstalledVersion ''
    }
    else {
        write-debug "Addon $id set to installed"
        Set-MyAddon -id $id -InstalledVersion ((Get-MyAddonsJoined -id $id).UpstreamVersion)
    }
    
}

function Update-MyAddonMeta {
    foreach ($addon in Get-MyAddonsJoined) {
        if ($addon.InstalledVersion -in '', $null -and $addon.enabled) {
            Set-MyAddon -State "Install pending" -id $addon.id
        }   
        elseif ($addon.InstalledVersion -notin '', $null -and !$addon.enabled) {
            Set-MyAddon -State "Uninstall pending" -id $addon.id
        }   
        elseif ($addon.InstalledVersion -notin '', $null -and $addon.InstalledVersion -ne $addon.UpstreamVersion) {
            Set-MyAddon -State "Update Available" -id $addon.id
        } 
        elseif ($addon.InstalledVersion -notin '', $null -and $addon.InstalledVersion -eq $addon.UpstreamVersion) {
            Set-MyAddon -State "Installed" -id $addon.id
        } 
        elseif ($addon.InstalledVersion -in '', $null -and !$addon.enabled) {
            Set-MyAddon -State "Not installed" -id $addon.id
        }
    }
}

#Update-MyAddonMeta