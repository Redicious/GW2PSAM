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
