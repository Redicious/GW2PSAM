
function global:GW2AddonManager {
    [CmdletBinding(DefaultParameterSetName='None')]
Param(
    [Parameter(Mandatory = $false,ParameterSetName='None')][String[]] $cmd,
    [Parameter(Mandatory = $false,ParameterSetName='auto')][Switch] $auto,
    [Parameter(Mandatory = $false,ParameterSetName='auto')][Switch] $keepopen,
    [Parameter(Mandatory = $false,ParameterSetName='help')][Switch] $help,
    [Parameter(Mandatory = $false)][Switch] $IgnoreRemoteUpdate,
    [Parameter(Mandatory = $false)][Switch] $NoParallelExec,
    [Parameter(Mandatory = $false)][Switch] $Exe
)

If ($PSBoundParameters["Debug"]) {
    $DebugPreference = "Continue"
}

$Version = "1.8.0.0" #Major.Minor.Build.Revision

function mylog
{
    param([string]$msg)

    $msg | out-file -filepath $LogPath -append
}

function mydebug 
{
    param([string]$msg)
    write-debug $msg
    mylog $msg    
}

# settings.ps1
# Settings

$AppDataPath = ($env:APPDATA) + "\GW2AddonsManager\"
$TranscriptPath = $AppDataPath + "transcript.txt"
$LogPath = $AppDataPath + "log.txt"

if(test-path $LogPath)
{
    remove-item $LogPath -ErrorAction SilentlyContinue
}
try{
    Stop-Transcript -ErrorAction SilentlyContinue | out-null
}
catch
{

}

start-transcript -path $TranscriptPath | Out-Null


$Bootstrap = $false
mydebug "Version = $Version"
$UseParallel = ![bool]($NoParallelExec)

$ForegroundcolorStatusInformation = "DarkGray"
$MenuHeadColor = "Cyan"
$MenuTextColor = "White"

# bootstrap.ps1
if(!$IgnoreRemoteUpdate)
{
    function GetVersion{
        param($strInput)
        [string]($strInput | select-string -pattern '\$Version.*=.*"(.*)"').matches.groups[1]
    }

    
    $URL = "https://raw.githubusercontent.com/Redicious/GW2PSAM/master/Gw2-AddonsManager.ps1"
    mydebug "getting remote code from $url"
    $RemoteBin = (Invoke-WebRequest -uri $URL -UseBasicParsing).Content
        $LocalBinPath = $AppDataPath + (Split-Path $URL -leaf)
    if($Exe)
    {
        $VersionLocal = $Version 
    }
    elseif (test-path $LocalBinPath) {
        mydebug "local binary exists at $LocalBinPath , reading the file..."
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
    mydebug "VersionRemote=""$VersionRemote"", VersionLocal=""$VersionLocal"""
    if($RemoteBin -in $null,'')
    {
        mydebug "couldn't retrieve remote information"
    }
    elseif (($LocalBin -or $exe) -and ( [System.Version]$VersionRemote -le [System.Version]$VersionLocal)) {
        
        mydebug "No remote Update, proceeding..."
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
                write-warning "there is an update available, updating myself from $($VersionLocal) to $($VersionRemote)..."
                #Compare-Object -ReferenceObject $RemoteBin -DifferenceObject $LocalBin
            }
            else {
                write-warning "installing..."
            }
            
            # Update local binary
            $RemoteBin | set-content -path $LocalBinPath -ErrorAction STOP
            
            mydebug "Call myself, updated/installed..."
            Get-Content $LocalBinPath -ErrorAction STOP -raw | Invoke-Expression
            switch ($PsCmdlet.ParameterSetName) {
                "None" { GW2AddonManager -cmd $cmd}
                "Help" { GW2AddonManager -help:$help }
                "Auto" { GW2AddonManager -auto:$auto -keepopen:$keepopen }
            }      

            # And cancel init of this instance, since we started a new one above
            Return 0
        }
    }
}
else {
    mydebug "remote ignored"
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

    mydebug "ask( QUEST=$Quest | PRESELECT=$Preselect | VALIDOPTIONS=$($Validoptions -join ',') | DELIMITER=$DELIMITER | VALIDATENOTNULLOREMPTY=$ValidateNotNullOrEmpty"

    if ($Delimiter) {
        $RXP = "^(" + ($ValidOptions -join '|') + ")" + "(" + $Delimiter + "(" + ($ValidOptions -join '|') + "))*$"
        mydebug "Regular Expression for input validation: $RXP"
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
    <add key="LogFile" value=""/>
    
    <!-- TacO stuff --> 
    <add key="TacODir" value='{{GW2Dir}}TacO\'/><!-- will be configurable.. at some point -->
    <add key="TacOExec" value='{{TacODir}}GW2TacO.exe'/>

    <!-- Blish-HUD stuff --> 
    <add key="BlishDir" value='{{GW2Dir}}Blish-HUD\'/><!-- will be configurable.. at some point -->
    <add key="BlishExec" value='{{BlishDir}}Blish HUD.exe'/>
    <add key="BlishUDir" value ="([Environment]::GetFolderPath('MyDocuments'))+'\Guild Wars 2\addons\blishhud\'" type ="ScriptBlock"/>
    
    <!-- arcdps stuff -->
    <add key="ArcDPSAddons" value="{{GW2Dir}}addons\arcdps\"/>

    <addons>
    <!-- 
        This part describes the addons
        - where und how to get them + some meta
        - dependencies/actions to other addons

        Don't mess with it
    -->        
        <addon id="1">
            <add key="Name" value="GW2Radial (DX9) (outdated)"/>
            <add key="DownloadURL" value='("https://github.com" + (((Invoke-WebRequest https://github.com/Friendly0Fire/GW2Radial/releases/tag/v2.1.3 -UseBasicParsing).content -split "`r`n" | select-string -pattern "`"\/.*GW2Radial\.zip`"" -AllMatches).matches.groups[0].value -replace """"));' type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download/(.*)/GW2Radial.zip" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="Website" value="https://github.com/Friendly0Fire/GW2Radial"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="DownloadTo" value="{{AddonTemp}}{{AddonName}}\GW2Radial.zip"/>
            <add key="UnzipTo" value="{{AddonTemp}}{{AddonName}}_Unzip\"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}" cleanup="1"/>
            <Step level="2" action="unzip" from="{{DownloadTo}}" to="{{UnzipTo}}" cleanup="1"/>
            <Step level="3" action="move" from="{{UnzipTo}}gw2radial\gw2addon_gw2radial.dll" to="{{GW2Dir}}bin64\d3d9_chainload.dll" IfIDs="4"/>
            <Step level="3" action="move" from="{{UnzipTo}}gw2radial\gw2addon_gw2radial.dll" to="{{GW2Dir}}bin64\d3d9.dll" IfNotIDs="4"/>
        </addon>
        <addon id="2">
            <add key="Name" value="TacO"/>
            <add key="GitHubU" value="BoyC"/>
            <add key="GitHubR" value="GW2TacO"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/{{GitHubU}}/{{GitHubR}}/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/{{GitHubU}}\/.*\.zip)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/(.*)\/.*.zip" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="{{AddonTemp}}{{AddonName}}\Taco.zip"/>
            <add key="RequiresAppClosed" value="{{TacOExec}}"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}" cleanup="1"/>
            <Step level="2" action="Unzip" from="{{DownloadTo}}" to="{{TacODir}}"/>
        </addon>
        <addon id="3">
            <add key="Name" value="TacO Tekkit Poi"/>
            <add key="DownloadURL" value="https://www.tekkitsworkshop.net/index.php/download?download=1:tw-all-in-one"/>
            <add key="UpstreamVersion" value='(irm -uri ("{{DownloadURL}}" -replace "\?.*") | select-string -pattern "ALL-IN-ONE MARKER PACK - (\d+\.\d+\.\d+)").matches.groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="{{TacODir}}POIs\tw_ALL_IN_ONE.taco"/>
            <add key="RequiresAppClosed" value="{{TacOExec}}"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        <addon id="4">    
            <add key="Name" value="Arc DPS (dx9)"/>
            <add key="DownloadURL" value="https://www.deltaconnected.com/arcdps/x64/d3d11.dll"/>
            <add key="UpstreamVersion" value='{{DownloadURL}}' type="WebHeaderLastModified"/>
            <add key="DownloadTo" value="{{GW2Dir}}bin64\d3d9.dll"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        <addon id="5">
            <add key="Name" value="Arc DPS Killproof.me (dx9)"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/knoxfighter/arcdps-killproof.me-plugin/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/knoxfighter.*d3d9_arcdps_killproof_me\.dll)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/v(.*)\/d3d9" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="{{GW2Dir}}bin64\d3d9_arcdps_killproof_me.dll"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="RequiresAddon" value="4"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        <addon id="6">
            <add key="Name" value="Arc DPS SCT (Scrolling Combat Text) (dx9)"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/Artenuvielle/GW2-SCT/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/Artenuvielle.*d3d9_arcdps_sct\.dll)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/(.*)\/d3d9" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="{{GW2Dir}}bin64\d3d9_arcdps_sct.dll"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="RequiresAddon" value="4"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        <addon id="7">
            <add key="Name" value="Arc DPS Boon Table (dx9)"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/knoxfighter/GW2-ArcDPS-Boon-Table/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/knoxfighter.*d3d9_arcdps_table\.dll)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/v(.*)\/d3d9" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="{{GW2Dir}}bin64\d3d9_arcdps_table.dll"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="RequiresAddon" value="4"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        <addon id="8">
            <add key="Name" value="Arc DPS Healing Stats (dx9)"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/Krappa322/arcdps_healing_stats/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/Krappa322.*arcdps_healing_stats\.dll)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/v(.*)\/arcdps_healing_stats" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="{{GW2Dir}}bin64\arcdps_healing_stats.dll"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="RequiresAddon" value="4"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        <addon id="10">
            <add key="Name" value="Blish-HUD"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/blish-hud/Blish-HUD/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/blish-hud.*Blish\.HUD.*.zip)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/v(.*)\/Blish\.HUD\." -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="'{{AddonTemp}}{{AddonName}}\'+('{{DownloadURL}}' | split-path -Leaf)" type="ScriptBlock"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}" cleanup="1"/>
            <Step level="2" action="Unzip" from="{{DownloadTo}}" to="{{BlishDir}}"/>
        </addon>
        <addon id="11">
            <add key="Name" value="Blish-HUD Tekkit Poi"/>
            <add key="DownloadURL" value="https://www.tekkitsworkshop.net/index.php/download?download=1:tw-all-in-one"/>
            <add key="UpstreamVersion" value='(irm -uri ("{{DownloadURL}}" -replace "\?.*") | select-string -pattern "ALL-IN-ONE MARKER PACK - (\d+\.\d+\.\d+)").matches.groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="{{BlishUDir}}markers\tw_ALL_IN_ONE.taco"/>
            <add key="RequiresAppClosed" value="{{BlishExec}}"/>
            <add key="RequiresAddon" value="10"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        <addon id="12">
            <add key="Name" value="Blish-HUD Hero Markers"/>
            <add key="GitHubU" value="QuitarHero"/>
            <add key="GitHubR" value="Heros-Marker-Pack"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/{{GitHubU}}/{{GitHubR}}/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/{{GitHubU}}\/.*\.zip)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/v(.*)\/.*.zip" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="'{{AddonTemp}}{{AddonName}}\'+('{{DownloadURL}}' | split-path -Leaf)" type="ScriptBlock"/>
            <add key="RequiresAppClosed" value="{{BlishExec}}"/>
            <add key="RequiresAddon" value="10"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}" cleanup="1"/>
            <Step level="2" action="Unzip" from="{{DownloadTo}}" to="{{BlishUDir}}markers\{{Name}}\"/>
        </addon>
        <addon id="13">
            <add key="Name" value="Blish-HUD Reactif Markers"/>
            <add key="DownloadURL" value="https://www.heinze.fr/taco/download.php?f=3"/>
            <add key="UpstreamVersion" value='{{DownloadURL}}' type="WebHeaderLength"/>
            <add key="DownloadTo" value="{{BlishUDir}}markers\GW2 TacO ReActif EN External.taco"/>
            <add key="RequiresAppClosed" value="{{BlishExec}}"/>
            <add key="RequiresAddon" value="10"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        <addon id="14">
            <add key="Name" value="Blish-HUD Tehs HP Trails"/>
            <add key="GitHubU" value="xrandox"/>
            <add key="GitHubR" value="TehsTrails"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/{{GitHubU}}/{{GitHubR}}/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/{{GitHubU}}\/.*\.taco)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/v(.*)\/.*.taco" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="'{{BlishUDir}}markers\'+('{{DownloadURL}}' | split-path -Leaf)" type="ScriptBlock"/>
            <add key="RequiresAppClosed" value="{{BlishExec}}"/>
            <add key="RequiresAddon" value="10"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}" />
        </addon>
        <addon id="20">
            <add key="Name" value="Addon Loader Core"/>
            <add key="GitHubU" value="gw2-addon-loader"/>
            <add key="GitHubR" value="loader-core"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/{{GitHubU}}/{{GitHubR}}/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/{{GitHubU}}\/.*\.zip)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/v(.*)\/.*.zip" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="'{{AddonTemp}}{{AddonName}}\'+('{{DownloadURL}}' | split-path -Leaf)" type="ScriptBlock"/>
            <add key="UnzipTo" value="'{{AddonTemp}}{{AddonName}}_Unzip\'" type="ScriptBlock"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}" cleanup="1" />
            <Step level="2" action="Unzip" from="{{DownloadTo}}" to="{{UnzipTo}}" cleanup="1"/>
            <Step level="3" action="move" from="{{UnzipTo}}addonLoader.dll" to="{{GW2Dir}}addonLoader.dll"/>
            <Step level="4" action="move" from="{{UnzipTo}}d3d11.dll" to="{{GW2Dir}}d3d11.dll"/>
            <Step level="5" action="move" from="{{UnzipTo}}dxgi.dll" to="{{GW2Dir}}dxgi.dll"/>
            <Step level="6" action="move" from="{{UnzipTo}}bin64\d3d9.dll" to="{{GW2Dir}}bin64\d3d9.dll"/>
        </addon>
        <addon id="21">
            <add key="Name" value="d3d9_wrapper"/>
            <add key="GitHubU" value="gw2-addon-loader"/>
            <add key="GitHubR" value="d3d9_wrapper"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/{{GitHubU}}/{{GitHubR}}/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/{{GitHubU}}\/.*\.zip)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/v(.*)\/.*.zip" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="'{{AddonTemp}}{{AddonName}}\'+('{{DownloadURL}}' | split-path -Leaf)" type="ScriptBlock"/>
            <add key="UnzipTo" value="'{{AddonTemp}}{{AddonName}}_Unzip\'" type="ScriptBlock"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="RequiresAddon" value="20"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}" cleanup="1"/>
            <Step level="2" action="Unzip" from="{{DownloadTo}}" to="{{UnzipTo}}" cleanup="1"/>
            <Step level="3" action="move" from="{{UnzipTo}}\{{GitHubR}}\gw2addon_d3d9_wrapper.dll" to="{{GW2Dir}}\addons\{{GitHubR}}\gw2addon_d3d9_wrapper.dll"/>            
            <Step level="4" action="move" from="{{UnzipTo}}\{{GitHubR}}\gw2addon_d3d9_wrapper.exp" to="{{GW2Dir}}\addons\{{GitHubR}}\gw2addon_d3d9_wrapper.exp"/>            
            <Step level="5" action="move" from="{{UnzipTo}}\{{GitHubR}}\gw2addon_d3d9_wrapper.lib" to="{{GW2Dir}}\addons\{{GitHubR}}\gw2addon_d3d9_wrapper.lib"/>            
            <Step level="6" action="move" from="{{UnzipTo}}\{{GitHubR}}\gw2addon_d3d9_wrapper.pdb" to="{{GW2Dir}}\addons\{{GitHubR}}\gw2addon_d3d9_wrapper.pdb"/>            
        </addon>
        <addon id="30">
            <add key="Name" value="GW2Radial (DX11)"/>
            <add key="GitHubU" value="Friendly0Fire"/>
            <add key="GitHubR" value="GW2Radial"/>
            <add key="DownloadURL" value='("https://github.com" + (((Invoke-WebRequest https://github.com/{{GitHubU}}/{{GitHubR}}/releases/latest/ -UseBasicParsing).content -split "`r`n" | select-string -pattern "`"\/.*GW2Radial\.zip`"" -AllMatches).matches.groups[0].value -replace """"));' type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download/v(.*)/GW2Radial.zip" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="RequiresAddon" value="21"/>
            <add key="DownloadTo" value="{{AddonTemp}}{{AddonName}}\GW2Radial.zip"/>
            <add key="UnzipTo" value="{{AddonTemp}}{{AddonName}}_Unzip\"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}" cleanup="1"/>
            <Step level="2" action="unzip" from="{{DownloadTo}}" to="{{UnzipTo}}" cleanup="1"/>
            <Step level="3" action="move" from="{{UnzipTo}}\{{GitHubR}}\gw2addon_gw2radial.dll" to="{{GW2Dir}}\addons\{{GitHubR}}\gw2addon_gw2radial.dll"/>
        </addon>
        <addon id="40">    
            <add key="Name" value="Arc DPS (dx11)"/>
            <add key="DownloadURL" value="https://www.deltaconnected.com/arcdps/x64/d3d11.dll"/>
            <add key="UpstreamVersion" value='{{DownloadURL}}' type="WebHeaderLastModified"/>
            <add key="DownloadTo" value="{{ArcDPSAddons}}gw2addon_arcdps.dll"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="RequiresAddon" value="20"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>        
        <addon id="41">
            <add key="Name" value="Arc DPS Killproof.me (dx11)"/>
            <add key="GitHubU" value="knoxfighter"/>
            <add key="GitHubR" value="arcdps-killproof.me-plugin"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/{{GitHubU}}/{{GitHubR}}/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/{{GitHubU}}.*d3d9_arcdps_killproof_me\.dll)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/v(.*)\/d3d9" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="{{ArcDPSAddons}}d3d9_arcdps_killproof_me.dll"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="RequiresAddon" value="40"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        <addon id="42">
            <add key="Name" value="Arc DPS SCT (Scrolling Combat Text) (dx11)"/>
            <add key="GitHubU" value="Artenuvielle"/>
            <add key="GitHubR" value="GW2-SCT"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/{{GitHubU}}/{{GitHubR}}/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/{{GitHubU}}.*d3d9_arcdps_sct\.dll)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/(.*)\/d3d9" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="{{ArcDPSAddons}}d3d9_arcdps_sct.dll"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="RequiresAddon" value="40"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        <addon id="43">
            <add key="Name" value="Arc DPS Boon Table (dx11)"/>
            <add key="GitHubU" value="knoxfighter"/>
            <add key="GitHubR" value="GW2-ArcDPS-Boon-Table"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/{{GitHubU}}/{{GitHubR}}/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/{{GitHubU}}.*d3d9_arcdps_table\.dll)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/v(.*)\/d3d9" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="{{ArcDPSAddons}}d3d9_arcdps_table.dll"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="RequiresAddon" value="40"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        <addon id="44">
            <add key="Name" value="Arc DPS Healing Stats (dx11)"/>
            <add key="GitHubU" value="Krappa322"/>
            <add key="GitHubR" value="arcdps_healing_stats"/>
            <add key="DownloadURL" value="'https://github.com'+((((Invoke-WebRequest https://github.com/{{GitHubU}}/{{GitHubR}}/releases/latest/ -UseBasicParsing).content | select-string -pattern '(\/{{GitHubU}}.*arcdps_healing_stats\.dll)' -AllMatches).matches[0].groups[1].value))"  type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download\/v(.*)\/arcdps_healing_stats" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="DownloadTo" value="{{ArcDPSAddons}}arcdps_healing_stats.dll"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="RequiresAddon" value="40"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}"/>
        </addon>
        <addon id="45">
            <add key="Name" value="Arc DPS Blish-Hud plugin"/>
            <add key="GitHubU" value="blish-hud"/>
            <add key="GitHubR" value="arcdps-bhud"/>
            <add key="DownloadURL" value='("https://github.com" + (((Invoke-WebRequest https://github.com/{{GitHubU}}/{{GitHubR}}/releases/latest/ -UseBasicParsing).content -split "`r`n" | select-string -pattern "`"\/.*-x86_64-pc-windows-gnu\.zip`"" -AllMatches).matches.groups[0].value -replace """"));' type="ScriptBlock"/>
            <add key="UpstreamVersion" value='("{{DownloadURL}}" | sls -pattern "download/v(.*)/.*-x86_64-pc-windows-gnu\.zip" -allmatches).Matches.Groups[1].value' type="ScriptBlock"/>
            <add key="RequiresAppClosed" value="{{GW2Exec}}"/>
            <add key="RequiresAddon" value="4"/>
            <add key="DownloadTo" value="{{AddonTemp}}{{AddonName}}\x86_64-pc-windows-gnu.zip"/>
            <add key="UnzipTo" value="{{AddonTemp}}{{AddonName}}_Unzip\"/>
            <Step level="1" action="download" from="{{DownloadURL}}" to="{{DownloadTo}}" cleanup="1"/>
            <Step level="2" action="unzip" from="{{DownloadTo}}" to="{{UnzipTo}}" cleanup="1"/>
            <Step level="3" action="move" from="{{UnzipTo}}arcdps_bhud.dll" to="{{GW2Dir}}bin64\arcdps_bhud.dll"/>
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
            mydebug "local setting file exists, reading..."
            $script:MyAddons = (get-content -path $MyAddonsFile -ErrorAction stop) | ConvertFrom-Json 
            foreach ($MyAddon in $MyAddons) {
                Update-MyAddon -id $MyAddon 
            }
        }
        else {
            mydebug "local setting file DOESN'T exists, creating new one"
            $script:MyAddons = @()
        }

        foreach ($Addon in $script:Addons) {
            if (!(Test-MyAddonExists -id $Addon.ID)) {
                Add-MyAddon -id $addon.id
            }
        }
    }
    if ($id) {
        mydebug "Get the selected addon with ID $ID"
        $script:MyAddons | Where-Object { $_.id -in $script:addons.id -and $_.id -eq $id }
        
    }
    else {
        mydebug "Get all addons"
        $script:MyAddons | Where-Object { $_.id -in $script:addons.id }
    }
    
}

function Test-MyAddonExists {
    param($id)
    mydebug "checking if addon with $id exists in settings"
    return ( $null -ne ($script:MyAddons | Where-Object { $_.ID -eq $id })  )
}

function Add-MyAddon( $id ) {
    mydebug "adding addon with id=$($addon.id) (name=$($addon.name)) to local settings"
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
    mydebug "enabling addon with ID $id"
    Set-MyAddon -id $id -Enabled $True
}

function Disable-MyAddon {
    param($id)
    mydebug "disabling addon with ID $id"
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
        mydebug "Addon $id set to uninstalled"
        Set-MyAddon -id $id -InstalledVersion ''
    }
    else {
        mydebug "Addon $id set to installed"
        Set-MyAddon -id $id -InstalledVersion ((Get-MyAddonsJoined -id $id).UpstreamVersion)
    }
    
}

function Update-MyAddonMeta {
    foreach ($addon in Get-MyAddonsJoined) {
        if($addon.UpstreamVersion -in '',$null,0 -or $addon.UpstreamVersion.trim() -eq '') {
            Set-MyAddon -State "Error" -id $addon.id
        }
        elseif ($addon.InstalledVersion -in '', $null -and $addon.enabled) {
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
    mydebug "ParseNodeValue $AddonID"
    $Val = $Node.value
    if ($Node.type -eq "Raw") {
        return $Val
    }
    else {
        $Val = ParseValue -Value $Val -AddonID $AddonID
        
        if ($Node.type -eq "ScriptBlock") {
            try {
                Invoke-Expression "$Val"
            }
            catch {
                write-error "Couldn't parse value $Val `r`nfrom Node:"
                write-error $Node.outerxml
                Throw $_
            }
        }
        elseif ($Node.type -eq "WebHeaderLastModified") {
            (Invoke-WebRequest $Val -method HEAD -UseBasicParsing).Headers."Last-Modified"
        }
        elseif ($Node.type -eq "WebHeaderLength") {
            (Invoke-WebRequest $Val -method HEAD -UseBasicParsing).Headers."Content-Length"
        }
        else {
            $Val
        }
    }
}
# Get the function's definition *as a string*
$ParseNodeValueAsString = $function:ParseNodeValue.ToString()

# find standard variables... so we can filter them later and don't carry them around
# try {
#     $GlobalStandardVariables = (powershell.exe '(get-variable).name') 
# }
# catch {
#     try {
#         $GlobalStandardVariables = (pwsh.exe '(get-variable).name') 
#     }
#     catch {
#         $GlobalStandardVariables = @('$', '?', '^')
#     }
# }


function ParseValue( $Value, [string]$AddonID ) {
    mydebug "ParseValue $AddonID $Value" 
    while ($Value | Select-String -pattern '{{(.+)}}') {
        $Attr = ($Value | Select-String -pattern '{{([\w\d]+)}}' -AllMatches).matches.groups[1].value
        $Value = $Value -replace [REGEX]::Escape('{{' + $attr + '}}'), (GetVar -key $Attr -AddonID $AddonID) 
    }
    Return $Value
}
$ParseValueAsString = $function:ParseValue.ToString()

function GetVar( [string]$key, [string]$AddonID) {
    mydebug "GetVar '$key' '$AddonID'"
    
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
$GVars = @()
write-host "Gathering information..." -ForegroundColor $ForegroundcolorStatusInformation
foreach ($add in (Select-Xml -Xml $XMLVars -XPath "/xml/add").node) {
    $Val = (ParseNodeValue -node $add)
    Set-Variable -Name $add.key -value $val -Scope Script 
    $GVars += [PSCustomObject]@{Name=($add.key);Value=$Val}
    mydebug "Global Var ""$($add.key)"" with val ""$Val"" scope 'Script'"
    $Val = $null
}

# addons
$script:addons = @()
write-host "Initializing addons..." -ForegroundColor $ForegroundcolorStatusInformation
if ($UseParallel -and $PSVersionTable.PSVersion.Major -ge 7) {
    mydebug "Parallel execution of addon init"
    (Select-Xml -Xml $XMLVars -XPath "/xml/addons/addon").node | foreach-object -parallel {
        # make functions available in here
        $function:ParseNodeValue = $using:ParseNodeValueAsString
        $function:ParseValue = $using:ParseValueAsString

        # also logging
        function mylog
        {
            param([string]$msg)
            $msg = ((get-date -format "yyyyMMdd_HHmmss:" )+$msg)
            $i=0
            while(!$done -and $i -lt 10)
            {
                try{
                    $msg | out-file -filepath $using:LogPath -append -ErrorAction stop
                    $done = $true
                }
                catch
                {
                    $i++;
                    start-sleep -seconds $i
                }

            }
        }

        function mydebug 
        {
            param([string]$msg)
            write-debug $msg
            mylog $msg    
        }

        # getVar is different in here... sadly
        function GetVar( [string]$key, [string]$AddonID) {
            mydebug "GetVar '$key' '$AddonID'"
            
            if ($AddonID) {
                if ($AddonID -eq $script:ObjAddon.id) {
                    if ($key -eq "AddonName") {
                        $val = $ObjAddon.name
                    }
                    else {
                        $val = $ObjAddon.$key    
                    } 
                }
                else {
                    throw "Oopsie... Shouldn't happen... yet... future stuff"
                }
            }
        
            if ($Null -eq $Val -or !$AddonID) {
                #$val = (Get-Variable -Scope using -Name $key -ValueOnly)
                $val = ($Using:GVars | ?{$_.name -eq $key }).value
            }
        
            if ($Null -eq $val) {
                Throw "couldn't get Variable $key for AddonID=$AddonID"
            }
            else {
                return $val
            }
        }

        # actual stuff
        $id = [int]$_.id
        $script:ObjAddon = [PSCustomObject]@{ id = $id }
    
        # simple vars
        foreach ($add in (Select-Xml -Xml $using:XMLVars -XPath "/xml/addons/addon[@id='$id']/add").node) {
            $Val = (ParseNodeValue -node $add -AddonID $id)    
            $script:ObjAddon | add-member -type NoteProperty -Name $add.key -value $val
        }
    
        $script:ObjAddon | Where-Object { $_.id -eq $id } | add-member -type NoteProperty -name "Steps" -value @()
        foreach ($step in (Select-Xml -Xml $using:XMLVars -XPath "/xml/addons/addon[@id='$id']/Step").node) {
            $objStep = new-object system.object
            foreach ($attr in @("IfIDs", "IfNotIDs", "from", "to", "level", "action")) {
                if ($step.$attr) {
                    $objStep | add-member -type NoteProperty -name $attr -value (parsevalue -value ($step.$attr) -Addonid $id)
                }
            }
            $script:ObjAddon.Steps += $objStep
        }
    
        # conditional vars
        mydebug "Addon Var ""$($add.key)"" with val ""$Val"""

        $ObjAddon
    } | foreach-object { $script:addons += $_ }
}
else {
    foreach ($addon in (Select-Xml -Xml $XMLVars -XPath "/xml/addons/addon").node) {
        mydebug "Sequential execution of addon init"
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
        mydebug "Addon Var ""$($add.key)"" with val ""$Val"""
        $Val = $null
    }
}

$GVars = $null

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
    by Redicious           https://github.com/Redicious/GW2PSAM/`r`n                           v$Version $(if($exe){"(.exe)"})`r`n" -BackgroundColor Black -ForegroundColor Red 
        }
        else {
            Write-Host "Welcome to
  __________      __________  
 /  _____/  \    /  \_____  \ 
/   \  __\   \/\/   //  ____/ 
\    \_\  \        //       \  Addonmanager
 \______  /\__/\  / \_______ \    by Redicious
        \/      \/          \/       v$Version $(if($exe){"(.exe)"})
 https://github.com/Redicious/GW2PSAM/`r`n" -BackgroundColor Black -ForegroundColor Red 
        } 
        
        if($PSVersionTable.psversion.major -lt 7)
        {
            write-warning "you are running an old version of PowerShell ($($PSVersionTable.psversion.tostring())), consider updating!"
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

        if (($JA | ? { $_.id -eq 10 }).InstalledVersion -notin '', $null) {
            @(
                [PSCustomObject]@{ ID = "B"; Text = "Run Blish Hud"; Function = "Invoke-BlishHud"; EXE=$true  },
                [PSCustomObject]@{ ID = "BR"; Text = "Run Blish Hud & GW2"; Function = "Invoke-BlishHud; Invoke-GW2"; EXE=$true  }
            )  | % { $Actions += $_ }
        }
        else {
            @(
                [PSCustomObject]@{ ID = "-"; Text = "Run Blish Hud (Not installed)"; Function = ""; EXE=$true  },
                [PSCustomObject]@{ ID = "-"; Text = "Run Blish Hud (Not installed) & GW2"; Function = ""; EXE=$true  }
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
            #[PSCustomObject]@{ ID = "S"; Text = "Create Desktop Shortcut"; Function = "CreateSortcut";},
            #[PSCustomObject]@{ ID = "SA"; Text = "Create Desktop Shortcut with Autostart"; Function = "CreateSortcut -auto" },
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
            mydebug "Adding addon to actions: $($J.ID) $($J.name): ""Toggle-Addon -id $($J.id)"" "
            $Actions += [PSCustomObject]@{ ID = $J.ID; Text = "Toggle enabled flag of Addon ""$($J.name)"""; Function = "Toggle-Addon -id $($J.id)" }
        }

        $Options = $Actions.ID | where-object { $_ -notin $null, '-', '' } | Sort-Object -Unique
        if($null -ne $cmd)
        {
            $Option = $cmd -split ","  
            write-host "Executing commands provided via parameter: $cmd"
            $cmd = $null  
        }
        else 
        {
            $Option = (ask -Quest "Enter your choice" -ValidOptions $Options -Delimiter ",")    
        }
        

        foreach ($O in $Option) {
            if ($O -eq "Q") {
                write-host "bye!"
                Stop-Transcript | out-null
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
    Invoke-GW2
    if (((Get-MyAddonsJoined -UpdateMeta) | ? { $_.id -eq 2 }).InstalledVersion -notin '', $null) {
        Invoke-Taco 
    }
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

function Invoke-BlishHud {
    write-host "starting Blish Hud $BlishExec"
    if (get-process | Where-Object { $_.path -eq $BlishExec }) {
        Write-Warning "Blish Hud already running!"
    }
    else {
        Start-Process -FilePath $BlishExec -WorkingDirectory $TacoDir

        #Sometimes it does not start...WHY!??! Just wait a few seconds and then try again. 
        $startTime = get-date   
        while((-not (get-process | Where-Object { $_.path -eq $BlishExec })) -and (new-timespan -start $startTime).Seconds -le 10)
        {
            start-sleep -seconds 1
        } 
        if((-not (get-process | Where-Object { $_.path -eq $BlishExec })))
        {
            Start-Process -FilePath $BlishExec -WorkingDirectory $TacoDir
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

                        $parentTo = split-path $step.to
                        if(!(test-path $parentTo))
                        {
                            new-item -type directory -path $parentTo -force -ErrorAction stop
                        }

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

# main.ps1
# main - after all prep is done, we can now actually display stuff to the user
if ($auto) {
    Invoke-AutomaticStart
}
else {
    Invoke-Menu    
}





}
