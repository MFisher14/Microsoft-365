# DataRecovery
A Repo of Helpful Tools to Recover Digital Data

## Microsoft 365 Data Recovery
If you're trying to recover information from a users email or OneDrive that's recently been deleted from a Microsoft Tenant, you can use the script below to easily and quickly recover the information.

#### Prerequisites
1. An administrator email and password for the tenant you're looking to perform the restoral in.
2. Make sure Powershell Version 7 is installed on your system. You can verify what version of Powershell you are running by opening PowerShell and running the `$PSVersionTable.PSVersion` command. If you do not currently have PowerShell Version 7 installed, you can install it directly from Microsoft by following this help article: [How to Install Powershell Version 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows)

#### Running the Script
1. To download the script, start by opening [this link](https://github.com/MFisher14/DataRecovery/blob/main/Microsoft%20365/PowerShell%20Scripts/deletedmailboxrestoral.ps1)
2. Use the download icon in the upper right to download the script. If you receive a pop-up asking if you want to download this script you will need to say yes.
3. Move the script to whatever location you prefer.
4. Open a new powershell window and use the following command, substituting the example filepath for the actual filepath of the script:
`C:\path\to\the\script\deletedmailboxrestoral.ps1 -ExecutionPolicy Bypass`
5. Follow the prompts in the script. If the account was fully removed from Microsoft 365, a user account will be created with the same UPN as before. You will be prompted to type a password.

The restoral process, depending on the size of the mailbox, can take some time. Once complete, you will be able to safely archive the data in your preferred format.
