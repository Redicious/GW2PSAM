
function global:GW2AddonManager {
    [CmdletBinding(DefaultParameterSetName='None')]
Param(
    [Parameter(Mandatory = $false,ParameterSetName='auto')][Switch] $auto,
    [Parameter(Mandatory = $false,ParameterSetName='auto')][Switch] $keepopen,
    [Parameter(Mandatory = $false,ParameterSetName='help')][Switch] $help,

    [Parameter(Mandatory = $false)][Switch] $IgnoreRemoteUpdate
)
If ($PSBoundParameters["Debug"]) {
    $DebugPreference = "Continue"
}
$Bootstrap = $false
$Version = "1.2.3" #Major.Feature/Improvement.Bugfix
write-debug "Version = $Version"