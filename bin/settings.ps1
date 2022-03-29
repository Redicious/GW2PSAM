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