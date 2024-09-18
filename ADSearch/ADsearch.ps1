# Import the Active Directory module if not already imported
Import-Module ActiveDirectory

# Automatically detect a domain controller
try {
    $DomainController = (Get-ADDomainController -Discover).Name
} catch {
    Write-Error "Failed to discover a domain controller. Ensure you have network connectivity and the AD module is available."
    exit
}

Write-Output "Welcome to the ADsearch Tool. " 

function Show-LockedOutAccounts {
    Write-Output "Locked out accounts:"
    $lockedOutAccounts = @(
        Search-ADAccount -Server $DomainController -LockedOut -UsersOnly | Select-Object Name, SamAccountName
    )

    if ($lockedOutAccounts.Count -gt 0) {
        $lockedOutAccounts | Format-Table -Property Name, SamAccountName -AutoSize

        # Prompt user for whether to unlock accounts only if there are locked accounts
        $unlockChoice = Read-Host "Unlock the Account(s)? (yes/no)"
        if ($unlockChoice -eq 'yes') {
            foreach ($account in $lockedOutAccounts) {
                try {
                    # Unlock the account
                    Unlock-ADAccount -Identity $account.SamAccountName
                    Write-Output "Unlocked account: $($account.Name)"
                } catch {
                    Write-Error "Failed to unlock account: $($account.Name). Error: $_"
                }
            }
        } else {
            Write-Output "Account(s) will not be unlocked."
            Write-Output ""
        }
    } else {
        Write-Output "No locked out accounts found."
        Write-Output ""
    }
}

function Show-ExpiredAccounts {
    $CurrentDate = Get-Date
    $ExpiredUsers = @(
        Get-ADUser -Filter {PasswordNeverExpires -eq $false -and Enabled -eq $true} -Properties PasswordLastSet |
        Where-Object {
            ($_.PasswordLastSet -eq $null) -or ($_.PasswordLastSet -lt $CurrentDate.AddDays(-90))
        }
    )

    if ($ExpiredUsers.Count -gt 0) {
        Write-Output "Expired Logins:"
        $ExpiredUsers | Select-Object Name, DistinguishedName | Format-Table -AutoSize
        Write-Output ""
    } else {
        Write-Output "No expired logins found."
        Write-Output ""
    }
}

function Show-DisabledAccounts {
    $displayDisabled = Read-Host "Display disabled accounts? (yes/no)"
    if ($displayDisabled -eq 'yes') {
        Write-Output ""
        Write-Output "Disabled Accounts:"
        $DisabledAccounts = @(
            Get-ADUser -Filter {Enabled -eq $false} -Properties DisplayName, LastLogonDate
        )
        if ($DisabledAccounts.Count -gt 0) {
            $DisabledAccounts | Select-Object Name, SamAccountName, LastLogonDate | Format-Table -AutoSize
        } else {
            Write-Output "No disabled accounts found."
        }
    } else {
        Write-Output "Disabled accounts will not be displayed."
        Write-Output ""
    }
}

function Show-FailedLogins {
    $displayFailedLogins = Read-Host "Display failed login attempts for the last 24 hours? (yes/no)"
    if ($displayFailedLogins -eq 'yes') {
        Write-Output ""
        Write-Output "Failed Login Attempts (Last 24 Hours):"

        # Define the time range for the last 24 hours
        $EndTime = Get-Date
        $StartTime = $EndTime.AddHours(-24)

        try {
            # Retrieve failed login attempts from the Security event log
            $failedLogins = @(
                Get-WinEvent -FilterHashtable @{
                    LogName   = 'Security'
                    Id        = 4625  # Event ID for failed login attempts
                    StartTime = $StartTime
                    EndTime   = $EndTime
                } -ErrorAction Stop
            )

            if ($failedLogins.Count -eq 0) {
                Write-Output "No failed login attempts found in the last 24 hours."
            } else {
                $failedLogins | Select-Object TimeCreated, Message | Format-Table -AutoSize
            }
        } catch {
            # Handle specific case for no matching events found
            if ($_.Exception.Message -match "No events were found") {
                Write-Output "No failed login attempts found in the last 24 hours."
            } else {
                Write-Error "An error occurred while retrieving failed login attempts. Ensure you have the necessary permissions to access the Security log."
            }
        }
    } else {
        Write-Output "Failed login attempts will not be displayed."
    }
}

function Lookup-User {
    $username = Read-Host "Enter the username to look up"
    Write-Output ""
    Write-Output "User Information for $username"
    try {
        # Run net user command to get user information
        net user $username
    } catch {
        Write-Error "An error occurred while retrieving user information for $username. Error: $_"
    }
    Write-Output ""
}

function Reset-UserPassword {
    $username = Read-Host "Enter Username"
    $newPassword = Read-Host "Enter New Password" -AsSecureString

    try {
        # Reset the user's password
        Set-ADAccountPassword -Identity $username -NewPassword $newPassword -Reset
        Write-Host "The password for user $username has been successfully reset."
    } catch {
        Write-Error "An error occurred while resetting the password for $username. Error: $_"
    }
    Write-Output ""
}

function Show-Menu {
    Write-Output ""
    Write-Output "Select an option:"
    Write-Output "1: Show Locked Out Accounts"
    Write-Output "2: Show Expired Accounts"
    Write-Output "3: Show Disabled Accounts"
    Write-Output "4: Show Failed Login Attempts"
    Write-Output "5: Lookup User"
    Write-Output "6: Reset User Password"
    Write-Output "Q: Quit"
}

while ($true) {
    Show-Menu
    $userChoice = Read-Host "Enter your choice"
    
    switch ($userChoice.ToLower()) {
        '1' { Show-LockedOutAccounts }
        '2' { Show-ExpiredAccounts }
        '3' { Show-DisabledAccounts }
        '4' { Show-FailedLogins }
        '5' { Lookup-User }
        '6' { Reset-UserPassword }
        'q' { exit }
        default { Write-Output "Invalid choice. Please enter a number between 1 and 6, or Q to quit." }
    }
}
