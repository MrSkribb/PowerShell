# Import CSV file into a variable
$companyUserMap = Import-Csv -Path "CompanyUserMap.csv"

# Function to get username and Boost URL based on company name
function Get-UserAndURLByCompany {
    param (
        [string]$companyName
    )

    $entry = $companyUserMap | Where-Object { $_.Company -eq $companyName }
    if ($entry) {
        return @{
            UPN  = $entry.UPN
            BoostURL = $entry.Boost
        }
    } else {
        return $null
    }
}

# Function to check delegate access for a specific user
function Get-DelegateAccess {
    param (
        [string]$UserToCheck
    )

    # Initialize a list to hold the results
    $delegateAccessList = @()

    # Retrieve all mailboxes and their permissions
    Get-Mailbox -ResultSize Unlimited | ForEach-Object {
        $mailbox = $_
        try {
            # Attempt to get mailbox permissions
            $permissions = Get-MailboxPermission -Identity $mailbox.Identity -ErrorAction Stop

            # Check if the user has delegate access
            foreach ($permission in $permissions) {
                if ($permission.User.ToString() -eq $UserToCheck -and $permission.AccessRights -contains "FullAccess") {
                    $delegateAccessList += [PSCustomObject]@{
                        Mailbox = $mailbox.DisplayName
                        EmailAddress = $mailbox.PrimarySmtpAddress
                        AccessRights = $permission.AccessRights
                    }
                }
            }
        } catch {
            # Ignore errors and continue processing other mailboxes
        }
    }

    # Display the results
    if ($delegateAccessList.Count -gt 0) {
        Write-Output "User $UserToCheck has delegate access to the following mailboxes:"
        $delegateAccessList | Format-Table -Property Mailbox, EmailAddress, AccessRights -AutoSize
    } else {
        Write-Output "User $UserToCheck does not have delegate access to any mailboxes."
    }
}

function DisplayInactive {

Write-Output "Inactive Accounts: " 
    
 # Define the cutoff date for inactivity
$cutoffDate = (Get-Date).AddDays(-90)

# Retrieve all mailboxes
$mailboxes = Get-Mailbox -ResultSize Unlimited

# Initialize an array to hold inactive mailboxes
$inactiveMailboxes = @()

# Retrieve mailbox statistics and filter based on inactivity
foreach ($mailbox in $mailboxes) {
    # Check if the mailbox has a DistinguishedName property
    if ($mailbox.DistinguishedName) {
        try {
            # Retrieve mailbox statistics using DistinguishedName
            $stats = Get-MailboxStatistics -Identity $mailbox.DistinguishedName
            
            # Extract last activity date and last logon date
            $lastActivityDate = $stats.LastActivityDate
            $lastLogonTime = $stats.LastLogonTime
            
            # Check if the mailbox has not had any activity (sent or received) in the last 90 days
            if (($lastActivityDate -lt $cutoffDate -or $lastActivityDate -eq $null) -and
                ($lastLogonTime -lt $cutoffDate -or $lastLogonTime -eq $null)) {
                
                # Add to the list of inactive mailboxes
                $inactiveMailboxes += [PSCustomObject]@{
                    DisplayName = $mailbox.DisplayName
                    PrimarySMTPAddress = $mailbox.PrimarySmtpAddress
                    LastActivityDate = $lastActivityDate
                    LastLogonTime = $lastLogonTime
                }
            }
        } catch {
            Write-Error "Failed to retrieve statistics for mailbox: $($mailbox.DisplayName). Error: $_"
        }
    } else {
        Write-Error "Mailbox does not have a DistinguishedName: $($mailbox.DisplayName)"
    }
}

# Display results
$inactiveMailboxes | Format-Table -AutoSize



}
function DisplayMailboxAliases {
    # Check if Get-Mailbox is available
    if (-not (Get-Command Get-Mailbox -ErrorAction SilentlyContinue)) {
        Write-Output "Get-Mailbox cmdlet is not available."
        return
    }

    do {
        Write-Output "Email Alias Lookup"
        Write-Output "Select an option:"
        Write-Output "1: Check a User's Aliases & Addresses"
        Write-Output "2: Check all Users' Aliases & Addresses"
        Write-Output "3: Quit"

        $choice = Read-Host "Enter your choice (1, 2, 3)"

        switch ($choice) {
            "1" {
                $userToCheck = Read-Host "Enter username to check: "
                $userDetails = Get-Mailbox -Identity $userToCheck | Select-Object DisplayName, RecipientType, PrimarySmtpAddress, EmailAddresses

                if ($userDetails) {
                    Write-Output "Email Address & Aliases Lookup:"
                    $userDetails | Format-List | Out-Host

                } else {
                    Write-Output "User not found or no details available."
                }
            }
            "2" {
                $users = Get-Mailbox | Select-Object DisplayName, RecipientType, PrimarySmtpAddress, EmailAddresses


                # Display the details in a table format with adjusted column widths
                $users | Format-Table -Property `
                    @{Name='DisplayName'; Expression={$_.DisplayName}; Width=30}, `
                    @{Name='RecipientType'; Expression={$_.RecipientType}; Width=20}, `
                    @{Name='PrimarySmtpAddress'; Expression={$_.PrimarySmtpAddress}; Width=40}, `
                    @{Name='Aliases'; Expression={
                        # Filter out SPO addresses and join the rest
                        $filteredAliases = $_.EmailAddresses | Where-Object { $_.ToString() -notlike 'SPO:*' }
                        $filteredAliases -join ', '
                    }; Width=100} -AutoSize | Out-Host
            }
            "3" {
                Write-Output "Exiting."
                Disconnect-ExchangeOnline -Confirm:$false
                break
            }
            default {
                Write-Output "Invalid choice. Please select 1, 2, or 3."
            }
        }
    } while ($choice -ne "3")
}




# Example usage
$companyName = Read-Host "Enter company name"
$result = Get-UserAndURLByCompany -companyName $companyName

if ($result) {
    $username = $result.UPN
    $boostURL = $result.BoostURL

    Write-Output "The username for $companyName is $username"

    if ($boostURL) {
        Write-Output "Opening Boost URL: $boostURL"
        Start-Process $boostURL
    } else {
        Write-Output "No Boost URL found for $companyName"
    }

    # Import and connect to Exchange Online
    Import-Module ExchangeOnlineManagement
    Connect-ExchangeOnline -UserPrincipalName $username 

    # Menu loop
    do {
        Write-Output "Exchange Online session is open."
        Write-Output "Select an option:"
        Write-Output "1: Check a User's Delegate Access"
        Write-Output "2: Email Address & Aliases Lookup"
        Write-Output "3: Display Inactive Accounts"
        Write-Output "4: Enter interactive shell"
        Write-Output "5: Quit"
       

        $choice = Read-Host "Enter your choice (1, 2, 3, 4, or 5)"
        Write-Output ""

        switch ($choice) {
            "1" {
                $userToCheck = Read-Host "Enter username to check: "
                Get-DelegateAccess -UserToCheck $userToCheck
            }
            "2" {
                DisplayMailboxAliases
            }
            "3" {
                DisplayInactive
            }
            "4" {
                Write-Output "Entering interactive shell. Type your commands below. Press 'q' and Enter to exit and disconnect."

                # Interactive Shell Mode with Error Handling
                while ($true) {
                    $command = Read-Host "PS>"
                    
                    # Check if the user wants to quit
                    if ($command -eq 'q') {
                        # Disconnect from Exchange Online
                        Disconnect-ExchangeOnline -Confirm:$false
                        Write-Output "Disconnected from Exchange Online."
                        break
                    }
                    
                    # Execute the command with error handling
                    try {
                        Invoke-Expression $command
                    } catch {
                        Write-Output "Error executing command: $_"
                    }
                }
            }
            "5" {
                Write-Output "Exiting."
                Disconnect-ExchangeOnline -Confirm:$false
                break
            }
            default {
                Write-Output "Invalid choice. Please enter 1, 2, 3, or 4."
            }
        }
    } while ($choice -ne "5")
} else {
    Write-Output "Company name not found."
}
