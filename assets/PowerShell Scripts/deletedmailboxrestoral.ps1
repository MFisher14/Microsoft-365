<#
.Created By: @MFisher14
.Purpose:   This script searches a designated Microsoft tenant and locates
.           all deleted mailboxes that aren't in your deleted users section
.           of the admin console, but are still recoverable.
.
.
#>

#Requires -Version 7

Write-Host @"
.         __  __ ______ _     _              __ _  _   
.   ____ |  \/  |  ____(_)   | |            /_ | || |  
.  / __ \| \  / | |__   _ ___| |__   ___ _ __| | || |_ 
. / / _' | |\/| |  __| | / __| '_ \ / _ \ '__| |__   _|
.| | (_| | |  | | |    | \__ \ | | |  __/ |  | |  | |  
. \ \__,_|_|  |_|_|    |_|___/_| |_|\___|_|  |_|  |_|  
.  \____/                                              
.                                                      
                                                                                         
"@ -ForegroundColor Yellow -BackgroundColor Red


$emailPattern = '^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'

## Install Required Modules (If Applicable)
$modules = @(
    # Required Packages & Modules
    "ExchangeOnlineManagement"
    "Microsoft.PowerShell.ConsoleGuiTools"
)

## Check if a module is installed
function Is-ModuleInstalled {
    param (
        [string]$ModuleName
    )
    return Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue
}

## Install a module if required
function Install-ModuleIfNeeded {
    param (
        [string]$ModuleName
    )
    if (-not (Is-ModuleInstalled -ModuleName $ModuleName)) {
        Write-Host "Module $ModuleName is not installed. Intalling..." -ForegroundColor Yellow -BackgroundColor Red
        Install-Module -Name $ModuleName -Force -Scope CurrentUser
        Write-Host "Module $ModuleName is now importing..." -ForegroundColor Yellow -BackgroundColor Red
        Import-Module -Name $ModuleName -ErrorAction SilentlyContinue
        Write-Host "The $ModuleName module is now installed." -ForegroundColor Black -BackgroundColor Green
    } else {
        Write-Host "The $ModuleName module is already installed." -ForegroundColor Black -BackgroundColor Green
    }
}

## Check if any module is not installed
$needsElevation = $false
foreach ($module in $modules) {
    if (-not (Is-ModuleInstalled -ModuleName $module)) {
        $needsElevation = $true
        break
    }
}

## Elevate to Administrator if needed
if ($needsElevation -and (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))) {
    ## Re-run the script as administrator
    Start-Process powershell.exe "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

## Install Required Modules
foreach ($module in $modules) {
    Install-ModuleIfNeeded -ModuleName $module
}

## Connect to Exchange Online
Connect-ExchangeOnline

## Get a list of Deleted Mailboxes
$deletedMailboxList = @()
$deletedMailboxes = Get-Mailbox -SoftDeletedMailbox

foreach ($deletedMailbox in $deletedMailboxes) {
    $deletedMailboxDisplayName = $deletedMailbox.DisplayName
    $deletedMailboxName = $deletedMailbox.Name
    $deletedMailboxUserPrincipalName = $deletedMailbox.UserPrincipalName
    $deletedMailboxWhenSoftDeleted = $deletedMailbox.WhenSoftDeleted
    $deletedMailboxExchangeGUID = $deletedMailbox.ExchangeGUID
    $ifInRestoralRequest = Get-MailboxRestoreRequest | Select-Object Name,TargetMailbox,Status | Where-Object { $_.TargetMailbox -eq $deletedMailboxDisplayName}
    if ($ifInRestoralRequest -ne $null) {$deletedMailboxRestoralRequest = $ifInRestoralRequest.Status} else { $deletedMailboxRestoralRequest = "Not Started"}
    $newMailbox = [PSCustomObject]@{DisplayName="$deletedMailboxDisplayName"; Name="$deletedMailboxName"; UserPrincipalName="$deletedMailboxUserPrincipalName"; WhenSoftDeleted="$deletedMailboxWhenSoftDeleted"; ExchangeGUID="$deletedMailboxExchangeGUID"; MailboxRestoralRequestStatus="$deletedMailboxRestoralRequest"}
    $deletedMailboxList += $newMailbox
}

$mailboxToRestore = $deletedMailboxList | Select-Object DisplayName,Name,UserPrincipalName,WhenSoftDeleted,ExchangeGUID,MailboxRestoralRequestStatus | Where-Object {$_.MailboxRestoralRequestStatus -ne "Completed"} | Out-ConsoleGridView -OutputMode Multiple -Title "Select the Mailboxes to Restore"


## Restore the selected Mailboxes
foreach ($deletedMailbox in $mailboxToRestore) {
    ## Local Variables
    $userDisplayName = $deletedMailbox.DisplayName
    $userPrincipalName2 = $deletedMailbox.UserPrincipalName

    ## Array where [0] is First Name and [1] is Last Name
    $userSplitName = $userDisplayName -Split " "

    ## Verify user account doesn't already exist
    $mailboxCheck = Get-Mailbox -Filter "DisplayName -eq '$userDisplayName'"
    if ($mailboxCheck -ne $null) {} else {
        ## Get a password for each user
        $userPassword = Read-Host -Prompt "Please enter a password for $userDisplayName" -AsSecureString
        ## Create a new mailbox
        New-Mailbox -MicrosoftOnlineServicesID $userPrincipalName2 -Alias (Get-Random -Maximum 10000) -Name $deletedMailbox.DisplayName -FirstName $userSplitName[0] -LastName $userSplitName[1] -Password $userPassword
        Write-Host "Pausing for 15 seconds to allow the account to finish creation..."
        Start-Sleep -Seconds 15

    }

    
    $targetMailbox = Get-Mailbox -Identity $userPrincipalName2
    New-MailboxRestoreRequest -SourceMailbox $deletedMailbox.ExchangeGUID -TargetMailbox $targetMailbox.Alias -AllowLegacyDNMismatch
    

Get-MailboxRestoreRequest | Where-Object { $_.Status -eq "InProgress"}


}

