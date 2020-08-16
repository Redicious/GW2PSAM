if($null -eq (Get-Variable -scope script -name 'XMLVars' -ValueOnly -ErrorAction SilentlyContinue))
{
    $XMLVars = [XML](get-content ".\vars.xml")
}

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
        else {
            $Val
        }
    }
}

function ParseValue( $Value, [string]$AddonID )
{
    write-debug "ParseValue $AddonID $Value" 
    while ($Value | Select-String -pattern '{{(.+)}}') {
        $Attr = ($Value | Select-String -pattern '{{([\w\d]+)}}' -AllMatches).matches.groups[1].value
        $Value = $Value -replace [REGEX]::Escape('{{'+$attr+'}}'),(GetVar -key $Attr -AddonID $AddonID) 
    }
    Return $Value
}

function GetVar( [string]$key, [string]$AddonID) {
    write-debug "GetVar '$key' '$AddonID'"
    
    if($AddonID)
    {
        if($key -eq "AddonName")
        {
            $val = (($script:addons | where-object { $_.id -eq $AddonID}).Name)
        }
        else {
            $val = (($script:addons | where-object { $_.id -eq $AddonID}).$key)    
        }
    }

    if($Null -eq $Val -or !$AddonID)
    {
        $val = (Get-Variable -Scope Script -Name $key -ValueOnly)
    }

    if($Null -eq $val)
    {
        Throw "couldn't get Variable $key for AddonID=$AddonID"
    }
    else
    {
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
        foreach($attr in @("IfIDs","IfNotIDs","from","to","level","action"))
        {
            if($step.$attr)
            {
                $objStep | add-member -type NoteProperty -name $attr -value (parsevalue -value ($step.$attr) -Addonid $id)
            }
        }
        ($script:Addons | Where-Object { $_.id -eq $id }).Steps += $objStep
    }

    # conditional vars
    write-debug "Addon Var ""$($add.key)"" with val ""$Val"""
    $Val = $null
}
