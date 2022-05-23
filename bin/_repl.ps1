param
(
    [switch]$whatif = $false
)
$repls = @(@("https://gitlab.deep-space-nomads.com/Redicious/guild-wars-2-addons-manager/-/raw/master/Gw2-AddonsManager.ps1","https://raw.githubusercontent.com/Redicious/GW2PSAM/master/Gw2-AddonsManager.ps1"),@("https://gitlab.deep-space-nomads.com/Redicious/guild-wars-2-addons-manager","https://github.com/Redicious/GW2PSAM"))


foreach($file in (gci "H:\Repositories\GW2\GH-guild-wars-2-addons-manager\*.ps1" -recurse | ?{ $_.name -ne "_repl.ps1"}))
{
    write-host "$file ..."
    $content  = $Ncontent =  ($file | get-content -ErrorAction stop)
    foreach($repl in $repls)    
    {
        write-host "$([REGEX]::ESCAPE($repl[0])) -> $($repl[1])"
        $NContent = $Ncontent -replace [REGEX]::ESCAPE($repl[0]),$repl[1]
    }
    if($whatif)
    {
        compare-object -DifferenceObject $Ncontent -ReferenceObject $Content
    }
    else 
    {
        $NContent | set-content -path $file.fullname   
    }
}