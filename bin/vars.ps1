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