if(!$IgnoreRemoteUpdate)
{
    $URL = "https://gitlab.deep-space-nomads.com/Redicious/guild-wars-2-addons-manager/-/raw/master/Gw2-AddonsManager.ps1"
    write-debug "getting remote code from $url"
    $RemoteBin = (Invoke-WebRequest -uri $URL).Content
    $LocalBinPath = ($env:TEMP) + "\GW2Addons\" + (Split-Path $URL -leaf)
    if (test-path $LocalBinPath) {
        write-debug "local binary exists at $LocalBinPath , reading the file..."
        $LocalBin = Get-Content $LocalBinPath -ErrorAction STOP -raw -encoding utf8
    }

    if($RemoteBin -in $null,'')
    {
        write-debug "couldn't retrieve remote information"
    }
    elseif ($LocalBin -and !(Compare-Object -ReferenceObject $RemoteBin -DifferenceObject $LocalBin)) {
        write-debug "No remote Update, proceeding..."
    }
    else {
        if(test-path $LocalBinPath)
        {
            write-warning "there is an update available, updating myself..."
            #Compare-Object -ReferenceObject $RemoteBin -DifferenceObject $LocalBin
        }
        else {
            write-warning "installing..."
        }
        
        # Update local binary
        $RemoteBin | set-content -path $LocalBinPath -ErrorAction STOP -encoding utf8
        
        write-debug "Call myself, updated/installed..."
        Get-Content $LocalBinPath -ErrorAction STOP -raw | Invoke-Expression
        switch ($PsCmdlet.ParameterSetName) {
            "None" { GW2AddonManager -debug:$debug}
            "Help" { GW2AddonManager -help:$help -debug:$debug}
            "Auto" { GW2AddonManager -auto:$auto -keepopen:$keepopen -debug:$debug}
        }      

        # And cancel init of this instance, since we started a new one above
        Return 0
    }
}
else {
    write-debug "remote ignored"
}
