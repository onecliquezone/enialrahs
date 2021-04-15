param(
    [Parameter(Mandatory=$true)][string]$AzureSubscriptionName,
    [Parameter(Mandatory=$true)][string]$ResourceGroupName,
    [Parameter(Mandatory=$true)][string]$Location,
    
    [Parameter(Mandatory=$true)][string]$AadWebClientId,
    [Parameter(Mandatory=$true)][string]$AadWebClientAppKey="",
    [Parameter(Mandatory=$true)][string]$AadTenantId,

    [Parameter(Mandatory=$true)][string]$FullDeploymentArmTemplateFile="",

    [Parameter(Mandatory=$false)][string]$clusterName="",
    [Parameter(Mandatory=$false)][string]$virtualMachineSize="",
    [Parameter(Mandatory=$false)][int]$diskSize,
   
    [Parameter(Mandatory=$true)][string]$adminUsername="",
    [Parameter(Mandatory=$true)][string]$adminPublicKey="",
   
    [Parameter(Mandatory=$false)][string]$cmsBaseURL="",
    [Parameter(Mandatory=$false)][string]$lmsBaseURL="",

    [Parameter(Mandatory=$false)][string]$installerGithubAccountName="",
    [Parameter(Mandatory=$false)][string]$installerGithubProjectName="",
    [Parameter(Mandatory=$false)][string]$installerGithubBranch="",

    [Parameter(Mandatory=$false)][string]$edxConfigurationGithubAccountName="",
    [Parameter(Mandatory=$false)][string]$edxConfigurationGithubProjectName="",
    [Parameter(Mandatory=$false)][string]$edxConfigurationGithubBranch=""

)


$azSecureApplicationKey = $AadWebClientAppKey | ConvertTo-SecureString -AsPlainText -Force
$azCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AadWebClientId, $azSecureApplicationKey
$isLoggedIn = [bool](Connect-AzAccount -Credential $azCredential -TenantId $AadTenantId -ServicePrincipal)

if($isLoggedIn){
    Select-AzSubscription -Subscription $AzureSubscriptionName
    Write-Host "Deploying Resource Group."
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location
    Write-Host "Deploying Template."

    $invocation = (Get-Variable MyInvocation).Value 
    $currentPath = Split-Path $invocation.MyCommand.Path 
    $rootPath = (get-item $currentPath).parent.FullName
    $parameterPath = "$($currentPath)\templates\stamp\parameters.json"

    $parmeters = Get-Content -Path $parameterPath | ConvertFrom-Json
   

    $armParameters = @{
        'clusterName'=(&{If($clusterName) {$clusterName} Else {$parmeters.parameters.clusterName.value}})
        'location'=(&{If($Location) {$Location} Else {$parmeters.parameters.location.value}})

        'virtualMachineSize'=(&{If($virtualMachineSize) {$virtualMachineSize} Else {$parmeters.parameters.virtualMachineSize.value}})
        'diskSize'=(&{If($diskSize -gt $parm.parameters.maxReturn.value) {$diskSize} Else {$parmeters.parameters.maxReturn.value}})

        'adminUsername'=(&{If($adminUsername) {$adminUsername} Else {$parmeters.parameters.adminUsername.value}})
        'adminPublicKey'="$((&{If($adminPublicKey) {$adminPublicKey} Else {$parmeters.parameters.adminPublicKey.value}}))"
        
        'installerGithubAccountName'=(&{If($installerGithubAccountName) {$installerGithubAccountName} Else {$parmeters.parameters.installerGithubAccountName.value}})
        'installerGithubProjectName'=(&{If($installerGithubProjectName) {$installerGithubProjectName} Else {$parmeters.parameters.installerGithubProjectName.value}})
        'installerGithubBranch'=(&{If($installerGithubBranch) {$installerGithubBranch} Else {$parmeters.parameters.name.value}})
        
        'edxConfigurationGithubAccountName'=(&{If($edxConfigurationGithubAccountName) {$edxConfigurationGithubAccountName} Else {$parmeters.parameters.edxConfigurationGithubAccountName.value}})
        'edxConfigurationGithubProjectName'=(&{If($edxConfigurationGithubProjectName) {$edxConfigurationGithubProjectName} Else {$parmeters.parameters.edxConfigurationGithubProjectName.value}})
        'edxConfigurationGithubBranch'=(&{If($edxConfigurationGithubBranch) {$edxConfigurationGithubBranch} Else {$parmeters.parameters.edxConfigurationGithubBranch.value}})
    }

    New-AzResourceGroupDeployment `
        -Name "OpenEdXTemplate" `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $FullDeploymentArmTemplateFile `
        -TemplateParameterObject $armParameters
}
else {
    Write-Error "Invalid Access."
}

