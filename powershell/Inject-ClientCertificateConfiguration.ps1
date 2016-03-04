Add-Type -Path "ezcert.util.dll"

function Inject-ClientCertificateConfiguration {
    Param(
        [string]$Path = $null
    )


    if (!$Path) {
        $Path = Get-ConfigPath -path (Get-Item -Path $PWD) -targetPath "web.config"
        if (!$Path) { throw "Couldn't find a web.config to modify. Are you in the right directory?" }
    }

    Write-Host "Adding <security> section to $Path"
    [ezcert.util.EnvironmentUtils]::InjectSecurityConfigSection($Path)
    Write-Host "Configuration updated"
}

