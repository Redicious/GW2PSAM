# for packaging one file
$Result = @()
$Result += get-content .\head.ps1 -raw
$Result += '# bootstrap.ps1'
$Result += get-content .\bootstrap.ps1 -raw
$Result += '# help.ps1'
$Result += get-content .\help.ps1 -raw
$Result += '# functions.ps1'
$Result += get-content .\functions.ps1 -raw
$Result += '# settings.ps1'
$Result += get-content .\settings.ps1 -raw
$Result += '# vars.xml'
$Result += '$XMLVars = [XML]'+"@'`r`n"+((get-content .\vars.xml -raw))+"`r`n'@"
$Result += '# myaddons.ps1'
$Result += get-content .\myaddons.ps1 -raw
$Result += '# vars.ps1'
$Result += get-content .\vars.ps1 -raw
$Result += '# menu.ps1'
$Result += get-content .\menu.ps1 -raw
$Result += '# addon_functions.ps1'
$Result += get-content .\addon_functions.ps1 -raw
$Result += '# main.ps1'
$Result += get-content .\main.ps1 -raw
$Result += '}'
$Result -join "`r`n" | Set-Content -path ..\Gw2-AddonsManager.ps1 -encoding unicode