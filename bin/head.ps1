
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

$Version = "1.8.1.0" #Major.Minor.Build.Revision

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
