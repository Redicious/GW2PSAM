[CmdletBinding(DefaultParameterSetName='None')]
Param(
    [Parameter(Mandatory = $false,ParameterSetName='auto')][Switch] $auto,
    [Parameter(Mandatory = $false,ParameterSetName='auto')][Switch] $keepopen,
    [Parameter(Mandatory = $false,ParameterSetName='help')][Switch] $help
)
If ($PSBoundParameters["Debug"]) {
    $DebugPreference = "Continue"
}
$Bootstrap = $false
$Version = "1.0"