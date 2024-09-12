# Import the Active Directory module if not already imported
Import-Module ActiveDirectory

# Automatically detect a domain controller
try {
    $DomainController = (Get-ADDomainController -Discover).Name
} catch {
    Write-Error "Failed to discover a domain controller. Ensure you have network connectivity and the AD module is available."
    exit
}

Write-Output ""

# Output header and run command for locked out accounts
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

# Output header and run command for expired accounts
$CurrentDate = Get-Date
$ExpiredUsers = @(
    Get-ADUser -Filter {PasswordNeverExpires -eq $false -and Enabled -eq $true} -Properties PasswordLastSet |
    Where-Object {
        ($_.PasswordLastSet -eq $null) -or ($_.PasswordLastSet -lt $CurrentDate.AddDays(-90))
    }
)

# Only display "Expired Logins" if there are any
if ($ExpiredUsers.Count -gt 0) {
    Write-Output "Expired Logins:"
    $ExpiredUsers | Select-Object Name, DistinguishedName | Format-Table -AutoSize
    Write-Output ""
} else {
    Write-Output "No expired logins found."
    Write-Output ""
}

# Prompt user for whether to display passwords expiring in the next 7 days
$displayExpiringPasswords = Read-Host "Display users with passwords expiring in 7 days? (yes/no)"
if ($displayExpiringPasswords -eq 'yes') {
    Write-Output ""
    Write-Output "Users with passwords expiring in the next 7 days:"

    # Define the time range for the next 7 days
    $ExpiryWarningDate = Get-Date
    $PasswordExpiringSoon = @(
        Get-ADUser -Filter {PasswordNeverExpires -eq $false -and Enabled -eq $true} -Properties PasswordLastSet, PasswordExpired, PasswordNeverExpires |
        Where-Object {
            $_.PasswordLastSet -ne $null -and 
            ($_.PasswordLastSet -lt $ExpiryWarningDate.AddDays(-90) -and $_.PasswordExpired -eq $false) -or 
            ($_.PasswordLastSet -eq $null)
        }
    )

    if ($PasswordExpiringSoon.Count -gt 0) {
        $PasswordExpiringSoon | Select-Object Name, SamAccountName, @{Name="PasswordLastSet";Expression={$_.PasswordLastSet}}, @{Name="PasswordExpiry";Expression={($_.PasswordLastSet).AddDays(90)}} | Format-Table -AutoSize
    } else {
        Write-Output "No expiring passwords."
    }
} else {
    Write-Output "Password expiry information will not be displayed."
}
Write-Output ""

# Prompt user for whether to display disabled accounts
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

# Prompt user for whether to display failed login attempts
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

        # Check if there are any failed logins
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
