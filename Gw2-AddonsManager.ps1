
function global:GW2AddonManager {
    [CmdletBinding(DefaultParameterSetName='None')]
Param(
    [Parameter(Mandatory = $false,ParameterSetName='auto')][Switch] $auto,
    [Parameter(Mandatory = $false,ParameterSetName='auto')][Switch] $keepopen,
    [Parameter(Mandatory = $false,ParameterSetName='help')][Switch] $help,
    [Parameter(Mandatory = $false)][Switch] $IgnoreRemoteUpdate,
    [Parameter(Mandatory = $false)][Switch] $Exe
)
If ($PSBoundParameters["Debug"]) {
    $DebugPreference = "Continue"
}
$Bootstrap = $false
$Version = "1.4.3" #Major.Feature/Improvement.Bugfix
write-debug "Version = $Version"


# bootstrap.ps1
if(!$IgnoreRemoteUpdate)
{
    function GetVersion{
        param($strInput)
        [string]($strInput | select-string -pattern '\$Version.*=.*"(.*)"').matches.groups[1]
    }

    
    $URL = "https://gitlab.deep-space-nomads.com/Redicious/guild-wars-2-addons-manager/-/raw/master/Gw2-AddonsManager.ps1"
    write-debug "getting remote code from $url"
    $RemoteBin = (Invoke-WebRequest -uri $URL -UseBasicParsing).Content
    $AppDataPath = ($env:APPDATA) + "\GW2AddonsManager\"
    $LocalBinPath = $AppDataPath + (Split-Path $URL -leaf)
    if($Exe)
    {
        $VersionLocal = $Version 
    }
    elseif (test-path $LocalBinPath) {
        write-debug "local binary exists at $LocalBinPath , reading the file..."
        $LocalBin = Get-Content $LocalBinPath -ErrorAction STOP -raw 
        $VersionLocal = (GetVersion $LocalBin)
    }
    else {
        $VersionLocal = 0
    }  

    if(!$exe -and !(test-path (split-path $LocalBinPath)))
    {
        new-item -type Directory -path (split-path $LocalBinPath) -erroraction silentlycontinue | out-null
    }

    $VersionRemote = (GetVersion $RemoteBin)
    write-debug "VersionRemote=""$VersionRemote"", VersionLocal=""$VersionLocal"""
    if($RemoteBin -in $null,'')
    {
        write-debug "couldn't retrieve remote information"
    }
    elseif (($LocalBin -or $exe) -and ( $VersionRemote -le $VersionLocal)) {
        
        write-debug "No remote Update, proceeding..."
    }
    else {
        if($exe)
        {
            write-warning "there is an update ($VersionRemote) available"
            pause
        }
        else
        {
            if(test-path $LocalBinPath)
            {
                write-warning "there is an update available, updating myself..."
                #Compare-Object -ReferenceObject $RemoteBin -DifferenceObject $LocalBin
            }
            else {
                write-warning "installing..."
            }
            
            # Update local binary
            $RemoteBin | set-content -path $LocalBinPath -ErrorAction STOP
            
            write-debug "Call myself, updated/installed..."
            Get-Content $LocalBinPath -ErrorAction STOP -raw | Invoke-Expression
            switch ($PsCmdlet.ParameterSetName) {
                "None" { GW2AddonManager }
                "Help" { GW2AddonManager -help:$help }
                "Auto" { GW2AddonManager -auto:$auto -keepopen:$keepopen }
            }      

            # And cancel init of this instance, since we started a new one above
            Return 0
        }
    }
}
else {
    write-debug "remote ignored"
}

# help.ps1
function Write-HelpPage{
    param([switch]$NoPause)
    Write-host "The help page is not finished... okay I didn't even start. Instead enjoy this puppy:"
    write-host '                      $$$$$$$$
               $$$$$$$::::::::$$$$$$$$$
             $$::::::::::::::::::::::::$$$$
            $$:::::::::::::::::::::::::::::$$
           $::::::::::::::::::::::::::::::::::$$
           $$:::::::::::::::::::::::::::::::::::$$
          $$::$$::::::::::::::::::::::$$::::::::::$$
        $$::$$:::$$$$:::::::::$$$$::::$$::::::::::$$$$
      $$:::$$::$$$$::$$:::::$$$$::$$:$$:::::::::::::$$$
      $$:::$$::::$$$$:::::::::$$$$:::$$:::::::::::::::$$
      $$:::$$::::::::::::::::::::::::$$:::::::::::::::$$
      $$::::$$:::::::::::::::::::::::$$:::::::::::::$$
        $$::$$::::$$$$$$:::::::::::::$$:::::::::::$$$
        $$::$$::$$::::::$$:::::::::::$$:::::::::$$
        $$::$$::$$::::::$$:::::::::::$$:::::::$$
          $$$$::::$$$$$$:::::::::::::$$$$::::$$$$
          $$$$:::::::::::::::::::::$$::$$::::$$$
           $$:$$$$$$$$$$$$:::::$$$$::::::$$$$:$$
             $$:::$$::::::$$$$$:::::::::::::::$$
             $$:::::$$$$$$$::::::::::::::::::::$$
             $$::::::::::::::::::::::::::::::::$$
            $$:::::::::::::::::::::::::::::::::$$
            $$:::::::::::::::::::::::::::::::::$$
            $$:::::::::::::::::::::::::::::::::::$
            $$:::::::::::::::::::::::::::::::::::$$
          $$:::::::::::::::::::::::::$$:::::::::::$
          $$::::::::::$$:::::::::::$$:::::::::::::$$
        $$::$$::::::::$$:::::::::$$:::::::::::::::$$
      $$::::$$::::::::::$$:::::::$$:::::::::::::::$$
      $$::::$$::::::::::::$$:::$$:::::::::::::::::$$
    $$::::::$$:::::::::::::$$:$$:::::::$$:::::::::$$
    $$::::::$$::::::::$$::::$$$::::::::$$:::::::::$$
    $$::::::$$::::::::$$::::$$$:::::::$$::::::::::$$
    $$::::::$$::::::::$$:::::::::::::::$$::::::::::$$
    $$::::::$$::::::::$$:::::::::::::::$$::::::::::::$
 $$$$:::::::$$::::::::$$:::::::::::::::$$::::::::::::$$
$:::$$::::::$$::::::::$$$$:::::::::::$$$$::::::::::::$$
$:::$$::::::$$::::::::$$::$$:::::::$$::$$::::::::::::$$
 $$$$$::::::$$::::::::$$::::$$:::$$:::::$$:::::::::::$$
    $$::::::$$::::::::$$::::::$$:::::::$$:::::::::::$$
    $$::::::$$::::::::$$:::::$$::::::::$$:::::::::::$$
  $$::::::::$$::::::::$$$$$$$$:::$$$$$$::$$:::::::::$$
  $$::::::::$$::::::::$$::::::$$$::::::$$$$:::::::::$$
$$::::::::$$::::::::::$$:::::::::$$$$$$::$$::::::::::$
$$::::::$$::::::::::$$$$$$$$$$$$$$$::::::$$::::::::::$
$$:$$:$$$::::::::::$$             $$$$$$$::$$:::::::::$
 $$$$$$$:::::::::::$$                      $$::::::::$$
     $$::$$::$$::$$:$                      $$::::::::::$$
      $$$$::$:::$::$$                      $$::::::::::::$
       $$:::$:::$::$                        $$:$::$$::$$::$
         $$$$$$$$$$                          $$:$:$$$$$$$$'
    if(!$NoPause)
    {
        Pause
    }
}


if($help){
    Write-HelpPage -NoPause
    Return
}
# functions.ps1
# general functions
function Copy-Object {
    param ( $InputObject )
    $OutputObject = New-Object PsObject
    $InputObject.psobject.properties | foreach-object {
        $OutputObject | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value
    }
    return $OutputObject
}

function Test-CrossContains {
    Param($a, $b)
    foreach ($an in $a) {
        if ($b -contains $an) {
            return $true
        }
    }
    foreach ($bn in $b) {
        if ($a -contains $bn) {
            return $true
        }
    }
    return $false    
}

function CreateAppdata {
    if (!(test-path $AppData)) {
        new-item -type Directory -path $appData -force | out-null
    }
}

function CreateSortcut {
    param([switch] $auto)
    if ($auto) {
        $name = "\GW2AddonManager(auto).lnk"
        $arguments = " -ExecutionPolicy Bypass -command gc $LocalBinPath -raw | iex; GW2AddonManager -auto; Pause "
    }
    else {
        $name = "\GW2AddonManager.lnk"
        $arguments = " -ExecutionPolicy Bypass -command gc $LocalBinPath -raw | iex; GW2AddonManager; Pause "
    }

    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut(([Environment]::GetFolderPath("Desktop") + $name))
    $Target = ($PSHome + "\PowerShell.exe")
    $Shortcut.TargetPath = $Target
    $Shortcut.Arguments = $arguments
    $Shortcut.Save()
    
}

function Get-GW2Dir {
    param([switch]$force)

    CreateAppdata
    # Already selected a folder
    if ((test-path -path $GW2DirFile -erroraction stop) -and ((Get-Content -path $GW2DirFile -erroraction stop).trim() -ne '')) {
        $Guess = (Get-Content -path $GW2DirFile).trim()
        if (!$force) {
            return ($guess.TrimEnd('\') + '\')
        }
    }     
    else {
        $Guess = Split-Path ((Get-ChildItem HKCU:\\system\GameConfigStore\Children\* | Get-ItemProperty).MatchedExeFullPath | ? { $_ -match 'gw2-64.exe$' } | select-object -first 1).trim()
    }

    $Result = ask -Quest "Is this the location you have Guild Wars 2 installed? `r`n$Guess`r`n [Y]es/[N]o/[C]ancel" -ValidOptions @("Y", "N", "C")
    if ($Result -eq "Y") {
        $guess | set-content -path $GW2DirFile
        Return ($Guess.TrimEnd('\') + '\')
        
    }
    elseif ($Result -eq "C") {
        Return ($Guess.TrimEnd('\') + '\')
    }
    elseif ($Result -eq "N") {
        $ResultN = (ask -Quest "Please enter the directory manually (Rightclick this window to paste your clipboard)" -ValidateNotNullOrEmpty)
        $ResultN | set-content -path $GW2DirFile
        return ($ResultN.TrimEnd('\') + '\')
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

    if ($Delimiter) {
        $RXP = "^(" + ($ValidOptions -join '|') + ")" + "(" + $Delimiter + "(" + ($ValidOptions -join '|') + "))*$"
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
            if ($Delimiter) {
                Return ($Result -split ",")
            }
            else {
                Return $Result    
            }
            
        }           
    } While (1) # yeah, bad style. Judge me
}
# settings.ps1
# Settings
$ForegroundcolorStatusInformation = "DarkGray"
$MenuHeadColor = "Cyan"
$MenuTextColor = "White"
# vars.xml
$XMLVars = [XML]@'
<xml>
    <!-- global vars -->
    <add key="AddonTemp" value='($env:TEMP) + "\GW2Addons\"' type="ScriptBlock"/>
    <add key="AppData" value='($env:APPDATA) + "\GW2AddonsManager\"' type="ScriptBlock"/>
    <add key="GW2DirFile" value='{{AppData}}\GW2Dir.txt' />
    <add key="GW2Dir" value='Get-GW2Dir' type="ScriptBlock"/>
    <add key="GW2Exec" value='{{GW2Dir}}Gw2-64.exe'/>
    <add key="MyAddonsFile" value='{{AppData}}MyAddons.JSON'/>
    <add key="LocalBinPath" value="{{AddonTemp}}Gw2-AddonsManager.ps1"/>
    
    <add key="TacODir" value='{{GW2Dir}}TacO\'/><!-- will be configurable.. at some point -->
    <add key="TacOExec" value='{{TacODir}}GW2TacO.exe'/> 
    <!--add key="CleanupTempDir" value="{{true}}"/-->
    <addons>
    <!-- 
        This part describes the addons
        - where und how to get them + some meta
        - dependencies/actions to other addons

        Don't mess with it
    -->        
        <addon id="1">
            <add key="Name" value="Radial Mount"/>
            <add key="DownloadURL" value='("https://github.com" + (((Invoke-WebRequest https://github.com/Friendly0Fire/GW2Radial/releases/latest -UseBasicParsing).content -split "`r`n" | select-string -pattern "`"\/.*GW2Radial\.zip`"" -AllMatches).matches.groups[0].value -replace """"));' type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download/(.*)/GW2Radial.zip" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="Website" value="https://github.com/Friendly0Fire/GW2Radial"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="DownloadTo" value="{{AddonTemp}}{{AddonName}}\GW2Radial.zip"/>
            <add key="UnzipTo" value="{{AddonTemp}}{{AddonName}}_Unzip\"/>
            <!--add key="DownloadTo" value="{{AddonTemp}}{{AddonName}}\d3d9.dll"/-->
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}" cleanup="1"/>
            <Step level="2" action="unzip" from="{{DownloadTo}}" to="{{UnzipTo}}" cleanup="1"/>
            <Step level="3" action="move" from="{{UnzipTo}}gw2radial\gw2addon_gw2radial.dll" to="{{GW2Dir}}bin64\d3d9_chainload.dll" IfIDs="4"/>
            <Step level="3" action="move" from="{{UnzipTo}}gw2radial\gw2addon_gw2radial.dll" to="{{GW2Dir}}bin64\d3d9.dll" IfNotIDs="4"/>
            <!-- prep for probable future cleanup step level="4" action="cleanupoldstuff" from="{{GW2Dir}}bin64\d3d9.dll" IfIDs="4">
            <step level="4" action="cleanupoldstuff" from="{{GW2Dir}}bin64\d3d9_chainload.dll" IfNotIDs="4"-->
        </addon>
        <addon id="2">
            <add key="Name" value="TacO"/>
            <add key="DownloadURL" value="((((Invoke-WebRequest http://www.gw2taco.com/ -UseBasicParsing).content | select-string -pattern '(https:.*\.zip)' -AllMatches).matches[0].groups[1].value)+'?dl=1')"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "GW2TacO_(.*)\.zip" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="{{AddonTemp}}{{AddonName}}\Taco.zip"/>
            <add key="RequiresAppClosed" value="{{TacOExec}}"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}" cleanup="1"/>
            <Step level="2" action="Unzip" from="{{DownloadTo}}" to="{{TacODir}}"/>
        </addon>
        <addon id="3">
            <add key="Name" value="TacO Tekkit Poi"/>
            <add key="DownloadURL" value="http://tekkitsworkshop.net/index.php/gw2-taco/download/send/2-taco-marker-packs/32-all-in-one"/>
            <add key="UpstreamVersion" value='{{DownloadURL}}' type="WebHeaderLastModified"/>
            <add key="DownloadTo" value="{{TacODir}}POIs\tw_ALL_IN_ONE.taco"/>
            <add key="RequiresAppClosed" value="{{TacOExec}}"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        <addon id="4">
            <add key="Name" value="Arc DPS"/>
            <add key="DownloadURL" value="https://www.deltaconnected.com/arcdps/x64/d3d9.dll"/>
            <add key="UpstreamVersion" value='{{DownloadURL}}' type="WebHeaderLastModified"/>
            <add key="DownloadTo" value="{{GW2Dir}}bin64\d3d9.dll"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="ArcDPSAddons" value="{{GW2Dir}}addons\arcdps"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        
        <addon id="5">
            <add key="Name" value="Arc DPS Killproof.me"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/knoxfighter/arcdps-killproof.me-plugin/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/knoxfighter.*d3d9_arcdps_killproof_me\.dll)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/v(.*)\/d3d9" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="{{GW2Dir}}bin64\d3d9_arcdps_killproof_me.dll"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="RequiresAddon" value="4"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        <addon id="6">
            <add key="Name" value="Arc DPS SCT (Scrolling Combat Text)"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/Artenuvielle/GW2-SCT/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/Artenuvielle.*d3d9_arcdps_sct\.dll)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/(.*)\/d3d9" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="{{GW2Dir}}bin64\d3d9_arcdps_sct.dll"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="RequiresAddon" value="4"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        <addon id="7">
            <add key="Name" value="Arc DPS Boon Table"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/knoxfighter/GW2-ArcDPS-Boon-Table/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/knoxfighter.*d3d9_arcdps_table\.dll)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/v(.*)\/d3d9" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="{{GW2Dir}}bin64\d3d9_arcdps_table.dll"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="RequiresAddon" value="4"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
    </addons>
</xml>
'@
# myaddons.ps1
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
# vars.ps1
# if($null -eq (Get-Variable -scope script -name 'XMLVars' -ValueOnly -ErrorAction SilentlyContinue))
# {
#     $XMLVars = [XML](get-content ".\vars.xml")
# }

function ParseNodeValue ( $Node, [string]$AddonID ) {
    write-debug "ParseNodeValue $AddonID"
    $Val = $Node.value
    if ($Node.type -eq "Raw") {
        return $Val
    }
    else {
        # while ($Val | Select-String -pattern '{{(.+)}}') {
        #     $Attr = ($Val | Select-String -pattern '{{([\w\d]+)}}' -AllMatches).matches.groups[1].value
        #     $Val = $Val -replace [REGEX]::Escape('{{'+$attr+'}}'),(GetVar -key $Attr -AddonID $AddonID) 
        # }

        $Val = ParseValue -Value $Val -AddonID $AddonID

        if ($Node.type -eq "ScriptBlock") {
            Invoke-Expression "$Val"
        }
        elseif ($Node.type -eq "WebHeaderLastModified") {
            (Invoke-WebRequest $Val -method HEAD -UseBasicParsing).Headers."Last-Modified"
        }
        else {
            $Val
        }
    }
}

function ParseValue( $Value, [string]$AddonID ) {
    write-debug "ParseValue $AddonID $Value" 
    while ($Value | Select-String -pattern '{{(.+)}}') {
        $Attr = ($Value | Select-String -pattern '{{([\w\d]+)}}' -AllMatches).matches.groups[1].value
        $Value = $Value -replace [REGEX]::Escape('{{' + $attr + '}}'), (GetVar -key $Attr -AddonID $AddonID) 
    }
    Return $Value
}

function GetVar( [string]$key, [string]$AddonID) {
    write-debug "GetVar '$key' '$AddonID'"
    
    if ($AddonID) {
        if ($key -eq "AddonName") {
            $val = (($script:addons | where-object { $_.id -eq $AddonID }).Name)
        }
        else {
            $val = (($script:addons | where-object { $_.id -eq $AddonID }).$key)    
        }
    }

    if ($Null -eq $Val -or !$AddonID) {
        $val = (Get-Variable -Scope Script -Name $key -ValueOnly)
    }

    if ($Null -eq $val) {
        Throw "couldn't get Variable $key for AddonID=$AddonID"
    }
    else {
        return $val
    }
}

# global vars
write-host "Gathering information..." -ForegroundColor $ForegroundcolorStatusInformation
foreach ($add in (Select-Xml -Xml $XMLVars -XPath "/xml/add").node) {
    $Val = (ParseNodeValue -node $add)
    Set-Variable -Name $add.key -value $val -Scope Script 
    write-debug "Global Var ""$($add.key)"" with val ""$Val"" scope 'Script'"
    $Val = $null
}

# addons
$script:addons = @()
write-host "Initializing addons..." -ForegroundColor $ForegroundcolorStatusInformation
foreach ($addon in (Select-Xml -Xml $XMLVars -XPath "/xml/addons/addon").node) {
    $id = [int]$addon.id
    $ObjAddon = [PSCustomObject]@{ id = $id }
    $script:addons += $ObjAddon

    # simple vars
    foreach ($add in (Select-Xml -Xml $XMLVars -XPath "/xml/addons/addon[@id='$id']/add").node) {
        $Val = (ParseNodeValue -node $add -AddonID $id)    
        $script:Addons | Where-Object { $_.id -eq $id } | add-member -type NoteProperty -Name $add.key -value $val
    }

    $script:addons | Where-Object { $_.id -eq $id } | add-member -type NoteProperty -name "Steps" -value @()
    foreach ($step in (Select-Xml -Xml $XMLVars -XPath "/xml/addons/addon[@id='$id']/Step").node) {
        $objStep = new-object system.object
        foreach ($attr in @("IfIDs", "IfNotIDs", "from", "to", "level", "action")) {
            if ($step.$attr) {
                $objStep | add-member -type NoteProperty -name $attr -value (parsevalue -value ($step.$attr) -Addonid $id)
            }
        }
        ($script:Addons | Where-Object { $_.id -eq $id }).Steps += $objStep
    }

    # conditional vars
    write-debug "Addon Var ""$($add.key)"" with val ""$Val"""
    $Val = $null
}

# menu.ps1
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
    by Redicious           https://gitlab.deep-space-nomads.com/Redicious/guild-wars-2-addons-manager/`r`n                           v$Version $(if($exe){"(.exe)"})`r`n" -BackgroundColor Black -ForegroundColor Red 
        }
        else {
            Write-Host "Welcome to
  __________      __________  
 /  _____/  \    /  \_____  \ 
/   \  __\   \/\/   //  ____/ 
\    \_\  \        //       \  Addonmanager
 \______  /\__/\  / \_______ \    by Redicious
        \/      \/          \/       v$Version $(if($exe){"(.exe)"})
 https://gitlab.deep-space-nomads.com/Redicious/guild-wars-2-addons-manager/`r`n" -BackgroundColor Black -ForegroundColor Red 
        } 
        
        $JA = Get-MyAddonsJoined -UpdateMeta

        $OptionIndex = ($JA | select-object id -ExpandProperty ID | sort-object ID -Descending | select-object -first 1) + 1

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
            [PSCustomObject]@{ ID = "I"; Text = "Update/install all enabled=1 and uninstall enabled=0"; Function = "Set-Addon"; EXE=$true  }
            #[PSCustomObject]@{ ID = $null; Text = "Update/install one addon..."; Function = "Set-Addon -select" }
        ) | % { $Actions += $_ }

        if (($JA | ? { $_.id -eq 2 }).InstalledVersion -notin '', $null) {
            @(
                [PSCustomObject]@{ ID = "T"; Text = "Run Taco"; Function = "Invoke-Taco"; EXE=$true  },
                [PSCustomObject]@{ ID = "TR"; Text = "Run Taco & GW2"; Function = "Invoke-Taco; Invoke-GW2"; EXE=$true  }
            )  | % { $Actions += $_ }
        }
        else {
            @(
                [PSCustomObject]@{ ID = "-"; Text = "Run Taco (Not installed)"; Function = ""; EXE=$true  },
                [PSCustomObject]@{ ID = "-"; Text = "Run Taco (Not installed) & GW2"; Function = ""; EXE=$true  }
            )  | % { $Actions += $_ }
        }

        @(
            [PSCustomObject]@{ ID = "A"; Text = "Update/Install/Uninstall + Run GW2 + Quit (like ""-auto"" parameter, ""H"" for more info)"; Function = "Invoke-AutomaticStart"; EXE=$true },
            [PSCustomObject]@{ ID = "R"; Text = "Run GW2"; Function = "Invoke-GW2"; EXE=$true  },
            [PSCustomObject]@{ ID = "F"; Text = "Run GW2 Repair (takes a while)"; Function = "Invoke-GW2 -Repair"; EXE=$true  },
            [PSCustomObject]@{ ID = "D"; Text = "Run GW2 Diagnose (takes a while)"; Function = "Invoke-GW2 -Diag"; EXE=$true  },
            [PSCustomObject]@{ ID = "C"; Text = "Change GW2 Installpath (Currently ""$GW2Dir"")"; Function = '$GW2Dir = (Get-GW2Dir -force)'; EXE=$true  },
            [PSCustomObject]@{ ID = "H"; Text = "Display help page, addon information and limitations of this tool"; Function = "Write-HelpPage" },
            [PSCustomObject]@{ ID = "N"; Text = "Nothing and Refresh the menu, I changed my window size!"; Function = ""; EXE=$true  },
            [PSCustomObject]@{ ID = "S"; Text = "Create Desktop Shortcut"; Function = "CreateSortcut";},
            [PSCustomObject]@{ ID = "SA"; Text = "Create Desktop Shortcut with Autostart"; Function = "CreateSortcut -auto" },
            #[PSCustomObject]@{ ID = "Res"; Text = "Reset addonmanager and exit"; Function = "" }
            [PSCustomObject]@{ ID = "Q"; Text = "Quit"; Function = "Quit()"; EXE=$true  }
        ) | % { $Actions += $_ }


        if($exe)
        {
            $actions = $actions | ?{ $_.Exe }
        }
        $Actions | Where-Object { $null -eq $_.id } | ForEach-Object { $_.id = $OptionIndex; $OptionIndex++ }
        
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
                Invoke-Expression $IEX    
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
    if (get-process | Where-Object { $_.path -eq $TacOExec }) {
        Write-Warning "Taco already running!"
    }
    else {
        Start-Process -FilePath $TacOExec -WorkingDirectory $TacoDir

        #Sometimes it does not start...WHY!??! Just wait a few seconds and then try again. 
        $startTime = get-date   
        while((-not (get-process | Where-Object { $_.path -eq $TacOExec })) -and (new-timespan -start $startTime).Seconds -le 10)
        {
            start-sleep -seconds 1
        } 
        if((-not (get-process | Where-Object { $_.path -eq $TacOExec })))
        {
            Start-Process -FilePath $TacOExec -WorkingDirectory $TacoDir
        }
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
# addon_functions.ps1
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
    $Addons | Where-Object { $_.enabled -eq $true -and ($_.InstalledVersion -in '', $null -or $_.InstalledVersion -ne $_.UpstreamVersion) } | ForEach-Object{ $InstallAddons += $_ }

    $AffectedIDs = @()
    $UninstallAddons.ID | ForEach-Object{ $AffectedIDs += $_ }
    $InstallAddons.ID | ForEach-Object{ $AffectedIDs += $_ }
    $AffectedIDs = $AffectedIDs | Where-Object{ $_ -notin '',0,$null }| Sort-Object -Unique



    # Find Addons that need to be reinstalled, due to above changes
    $ReinstallAddons = $Addons | Where-Object { (Test-CrossContains -a $_.Steps.IfIds -b $AffectedIDs) -or  (Test-CrossContains -a $_.Steps.IfNotIds -b $AffectedIDs) } 
    $ReinstallAddons | ForEach-Object { $UninstallAddons += $_; $InstallAddons += $_   }

    write-debug "those addons need reinstallement (affectedIDs=$($AffectedIDs -join ', ')): $($ReinstallAddons.Id -join ', ')"

    # Check for running application
    $UninstallAddons.RequiresAppClosed | Sort-Object -Unique | ForEach-Object{ RequireAppClosed -Path $_ -ErrorAction STOP } | ForEach-Object{ if($_ -contains "cancel") { return } else { $_ }}
    $InstallAddons.RequiresAppClosed | Sort-Object -Unique | ForEach-Object{ RequireAppClosed -Path $_ -ErrorAction STOP } | ForEach-Object{ if($_ -contains "cancel") { return } else { $_ }}
    
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
                            Write-debug "Can't perform undo for unzipping $($step.from) to $($step.to) - sorry, but the risk is too high. For now... "
                        }
                        elseif($step.from -match "\*")
                        {
                            Write-debug "Can't perform undo for moving or copying with wildcards  $($step.from) to $($step.to) - sorry for wasting disk space, but the risk is too high. For now... "
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

# main.ps1
# main - after all prep is done, we can now actually display stuff to the user
if ($auto) {
    Invoke-AutomaticStart
}
else {
    Invoke-Menu    
}





}
