[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory,Position=0)]$FileName,
    [Parameter(Mandatory,Position=1)]$MAX_ACCOUNTS = 0,
    [Parameter(Mandatory=$false)][Switch]$useSamAccountName = $false
)

if ($MAX_ACCOUNTS -eq 0)
{
    Write-Output "None"
    return
}

$Accounts = 0
$ErrorActionPreference = "Stop"
#$notfounds = @()

Write-Output "Loading $FileName"
$imports = Import-CSV $FileName

Write-Output "Loading UserPrincipalNames"
$mails = get-aduser -Filter *  -Properties 'Mail' | select -expand mail

Write-Output "Loading Provisioned Mailboxes"
$exports = Get-RemoteMailbox -ResultSize Unlimited | Where { $_.RemoteRecipientType -eq 'ProvisionMailbox' } | select -expand PrimarySmtpAddress

foreach($import in $imports)
{
    $PrimarySmtpAddress = $import.PrimarySmtpAddress.ToString()

    #if (-not $mails.contains($PrimarySmtpAddress))
    #{
    #        Write-Output "$PrimarySmtpAddress not found in AD"
    #        $notfounds += ,$PrimarySmtpAddress
    #}
    #else
    #{
        #break
        if (-not $exports.contains($PrimarySmtpAddress))
        {
            if ($useSamAccountName) {
                $target = $import.SamAccountName.ToString()
            }
            else {
                $target = "$PrimarySmtpAddress"
            }

            Write-Output "$target"

            $RemoteRoutingAddress = $import.RemoteRoutingAddress.ToString()
            $LegacyExchangeDN = $import.LegacyExchangeDN.ToString()
            $emailaddresses = $import.EmailAddresses.Split(";")

            if($PSCmdlet.ShouldProcess($target, "Enable-remotemailbox")) {
                Enable-remotemailbox "$target" `
                    -PrimarySmtpAddress "$PrimarySmtpAddress" `
                    -remoteroutingAddress "$RemoteRoutingAddress" `
                    -ErrorAction Stop
            }

            if($PSCmdlet.ShouldProcess($target, "Set-RemoteMailbox EmailAddressPolicyEnabled false")) {
                Set-remotemailbox "$target" -PrimarySmtpAddress "$PrimarySmtpAddress" `
                    -EmailAddressPolicyEnabled $false `
                    -ErrorAction Stop
            }

            foreach($emailaddress in $emailaddresses)
            {
                if($PSCmdlet.ShouldProcess($target, "Set-RemoteMailbox add email $emailaddress")) {
                    Set-remotemailbox "$target" -EmailAddresses  @{add="$emailaddress"} `
                        -ErrorAction Stop
                }
            }
            if($PSCmdlet.ShouldProcess($target, "Set-RemoteMailbox add email $LegacyExchangeDN")) {
                Set-remotemailbox "$target" -EmailAddresses @{add="x500:$LegacyExchangeDN"} `
                    -ErrorAction Stop
            }

            $Accounts = $Accounts + 1
            if ($Accounts -ge $MAX_ACCOUNTS) {
                   break
            }
        }
    #}
}

if ($notfounds.count -gt 0) {
    Write-Output "Not founds in AD -------------"
    foreach ($notfound in $notfounds) {
        Write-Output "$notfound not found in AD"
    }
}

