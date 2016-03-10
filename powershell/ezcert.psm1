$infoColor = 'cyan'
$errorColor = 'red'
$logColor = 'green'

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path
$ezCertExecutablePath = "$moduleRoot/ezcert.exe"

. "$moduleRoot\utils.ps1"
. "$moduleRoot\Functions\New-LocalCA.ps1"
. "$moduleRoot\Functions\New-LocalClientCert.ps1"
. "$moduleRoot\Functions\Initialize-ClientCertConfig.ps1"
. "$moduleRoot\Functions\Unlock-AppHostSecuritySection.ps1"
. "$moduleRoot\Functions\Initialize-LocalClientCerts.ps1"
