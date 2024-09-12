# Cloud-Shell.ps1

Sometimes using the cloud shell in 365 (Azure CLI) is not always an option - This script provides the ability to run a PowerShell session that connects to Microsoft Exchange as well as utilising many preset features and an easy-to-use menu.

Features consist of the following:

Prompts the user for a company name --> Then automatically opens and authenticates an admin user based on an imported .csv file which is meant to be prefilled with the following (Company Name, 365 Admin Email, Web Url to locally stored account -information which opens automatically in a default browser, something like Sharepoint, GoogleDrive could be used for this)
Uses an interactive and simple menu to navigate through the features
Spawn an interactive PowerShell session that operates exactly the same as Azure CLI
Display Inactive Accounts in 365
Display all email addresses and their aliases
Lookup all aliases for one specified user
Display all mailboxes a user has delegate access to

# Requirements & Setup

Requirements:
•	PowerShell NuGet Provider Version > 2.8.5.xxx 
•	PowerShell Module: ExchangeOnlineManagement
•	ExecutionPolicy set to ‘RemoteSigned’
•	Company list csv (In the same directory)

Setup:
A few things must be installed on your local machine to run this script. 
Run this command in a PowerShell window: 
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser

You will get a prompt, select Yes. | You may also get another prompt, select ‘Yes to All’
Open a PowerShell window as administrator and do the following command: 
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
A prompt will show, type ‘A’ and click Enter

