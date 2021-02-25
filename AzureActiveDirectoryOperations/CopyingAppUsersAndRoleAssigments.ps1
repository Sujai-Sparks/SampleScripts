<#
.SYNOPSIS
	Copy Users/Groups and Role Assignments from Enterprise Application to the other.
	Source: https://github.com/Sujai-Sparks/SampleScripts/blob/main/AzureActiveDirectoryOperations/CopyingAppUsersAndRoleAssigments.ps1

.DESCRIPTION
	This Sample powershell script copies the Groups and Users and their role assignments from Enterprise Application to the other in the same AAD. 
	This script assumes that there are two roles, viz., Contributor and Reader role.
	Before copying the Users and Groups, it does check if the identity already exists in the target application's Users and Groups list. If so, skip those identities.
      
.Parameter SrcEnterpriseAppName
	Source Enterprise Application Name from which the Users and Groups need to be copied.

.Parameter TrgEnterpriseAppName
	Enterprise Application Name to which the Users and Groups need to be copied.

.Example
	PS C:\WINDOWS\system32> C:\MySampleScripts\AzureActiveDirectoryOperations\MovingAppUsersAndRoleAssigments.ps1

#>

#region Parameters
Param
(
    
    [Parameter(Mandatory=$true, HelpMessage="Enter Source Enterprise Application Name ")]
    [string] $SrcEnterpriseAppName ,
    
    [Parameter(Mandatory=$true, HelpMessage="Enter Target Enterprise Application Name ")]
    [string] $TrgEnterpriseAppName 
    
)
#endregion 

#region Initialize

# Install AzureAD module if not already installed
Install-Module -Name AzureAD -AllowClobber

# Prompt for Credentials
$aadUserCredential = $host.ui.PromptForCredential("Need credentials", "Please enter your AAD user name and password.", "", "Domain")

Write-Host $aadUserCredential

# Sign in as a user that's allowed to manage enterprise applications in AAD
Connect-AzureAD -Credential $aadUserCredential

#endregion 

#region Source Enterprise Application Get Details

#Getting details of the Source Enterprise Application
$SrcEnterpriseApp = Get-AzureADServicePrincipal -All:$true | Where-Object { $_.Displayname -eq $SrcEnterpriseAppName } 
$SrcServicePrincipalId = $SrcEnterpriseApp.ObjectId


#Getting Source Enterprise Application Roles
$SrcAppRoles = $SrcEnterpriseApp.AppRoles
$SrcContributorAppRoleId = @($SrcAppRoles | Where-Object {$_.Displayname -contains "Contributor"}).Id
$SrcReaderAppRoleId = @($SrcAppRoles | Where-Object {$_.Displayname -contains "Reader"}).Id

#Getting all App Role Assignments
$SrcContributorAppRoleAssignments = Get-AzureADServiceAppRoleAssignment -ObjectId $SrcServicePrincipalId | Where-Object { $_.Id -eq $SrcContributorAppRoleId } 

$SrcReaderAppRoleAssignments = Get-AzureADServiceAppRoleAssignment -ObjectId $SrcServicePrincipalId | Where-Object { $_.Id -eq $SrcReaderAppRoleId } 

#endregion

#region Target Enterprise Application Get Details

#Getting details of the Target Enterprise Application
$TargetEnterpriseApp = Get-AzureADServicePrincipal -All:$true | Where-Object { $_.Displayname -Contains $TrgEnterpriseAppName } 
$TrgServicePrincipalId = $TargetEnterpriseApp.ObjectId


#Getting Source Enterprise Application Roles
$TrgAppRoles = $TargetEnterpriseApp.AppRoles
$TrgContributorAppRoleId = @($TrgAppRoles | Where-Object {$_.Displayname -contains "Contributor"}).Id
$TrgReaderAppRoleId = @($TrgAppRoles | Where-Object {$_.Displayname -contains "Reader"}).Id

#endregion

#region Copy Assignments - Users and their Roles

#First lets move all Contributor Role users and groups
if ($TrgContributorAppRoleId -ne $null)
{
    foreach($AssignmentId in $SrcContributorAppRoleAssignments) 
    {
        $UserDisplayName = $AssignmentId.PrincipalDisplayName
        $UserPrincipalId = $AssignmentId.PrincipalId
        $PrincipalType = $AssignmentId.PrincipalType
        $UserObjectId = $AssignmentId.ObjectId
        Write-Host "Adding $UserDisplayName to Contributor Role $TrgContributorAppRoleId"
        
        $UserExists = Get-AzureADServiceAppRoleAssignment -ObjectId $TrgServicePrincipalId | Where-Object {$_.PrincipalDisplayName -eq $UserDisplayName}

        if ($UserExists -eq $null)
        {
            if ($PrincipalType -eq "Group")
            {
                New-AzureADGroupAppRoleAssignment -ObjectId $UserPrincipalId -PrincipalId $UserPrincipalId -ResourceId $TrgServicePrincipalId -Id $TrgContributorAppRoleId
            }
            elseif ($PrincipalType -eq "User")
            {
                New-AzureADUserAppRoleAssignment -ObjectId $UserPrincipalId -PrincipalId $UserPrincipalId -ResourceId $TrgServicePrincipalId -Id $TrgContributorAppRoleId
            }
        }
    }
}

#Next lets move all Contributor Role users and groups
if ($TrgReaderAppRoleId -ne $null)
{
    foreach($AssignmentId in $SrcReaderAppRoleAssignments) 
    {
        $UserDisplayName = $AssignmentId.PrincipalDisplayName
        $UserPrincipalId = $AssignmentId.PrincipalId
        $PrincipalType = $AssignmentId.PrincipalType
        $UserObjectId = $AssignmentId.ObjectId
        Write-Host "Adding $UserDisplayName to Reader Role $TrgReaderAppRoleId"
        
        $UserExists = Get-AzureADServiceAppRoleAssignment -ObjectId $TrgServicePrincipalId | Where-Object {$_.PrincipalDisplayName -eq $UserDisplayName}
        
        if ($UserExists -eq $null)
        {
            if ($PrincipalType -eq "Group")
            {
                New-AzureADGroupAppRoleAssignment -ObjectId $UserPrincipalId -PrincipalId $UserPrincipalId -ResourceId $TrgServicePrincipalId -Id $TrgReaderAppRoleId
            }
            elseif ($PrincipalType -eq "User")
            {
                New-AzureADUserAppRoleAssignment -ObjectId $UserPrincipalId -PrincipalId $UserPrincipalId -ResourceId $TrgServicePrincipalId -Id $TrgReaderAppRoleId
            }
        }
    }
}

#endregion

