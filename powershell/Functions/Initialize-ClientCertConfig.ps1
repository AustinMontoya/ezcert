function Initialize-ClientCertConfig {
    Param(
        [string]$Path = $null
    )

    if (!$Path) {
        $Path = Get-ConfigPath -path (Get-Item -Path $PWD) -targetPath "web.config"
        if (!$Path) { throw "Couldn't find a web.config to modify. Are you in the right directory?" }
    }

    Write-Log "Adding <security> section to $Path"
    & $ezcertExecutablePath InjectSecurityConfigSection -configPath="$Path"
    Write-Success "Configuration updated"
}

