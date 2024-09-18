# PowerShell Scripts
A repo that contains all my PowerShell scripts

# Cloud-Shell.ps1 
Sometimes using the cloud shell in 365 (Azure CLI) is not always an option - This script provides the ability to run a PowerShell session that connects to Microsoft Exchange as well as utilising many preset features and an easy-to-use menu. 

Features consist of the following:
- Prompts the user for a company name --> Then automatically opens and authenticates an admin user based on an imported .csv file which is meant to be prefilled with the following (Company Name, 365 Admin Email, Web Url to locally stored account -information which opens automatically in a default browser, something like Sharepoint, GoogleDrive could be used for this)
- Uses an interactive and simple menu to navigate through the features
- Spawn an interactive PowerShell session that operates exactly the same as Azure CLI
- Display Inactive Accounts in 365
- Display all email addresses and their aliases
- Lookup all aliases for one specified user
- Display all mailboxes a user has delegate access to

See more in the CLoud-Shell Directory

# ADsearch.ps1

This script's purpose is to centralise, streamline and automate various active directory functions and tasks. Allowing the user to see critical information for problematic user accounts in one place and action issues if required with a simple command

Features consist of the following:
- Simple and effective menu system
- Displays locked accounts
- Prompts to unlock the locked accounts
- Displays disabled accounts
- Displays accounts with expired logins
- Lookup user feature - Displays information about a user via net user
