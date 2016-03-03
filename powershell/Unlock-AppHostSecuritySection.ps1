Add-Type -Path 'ezcert.util.dll'

function Unlock-AppHostSecuritySection {
    Param(
        [string]$Path
    )

    if (!$Path) {
        Write-Host "Searching for applicationhost.config..."
        $Path = Get-AppHostConfigPath((Get-Item -Path $PWD))
    }

    Write-Host "Modifying $Path"
    [ezcert.util.EnvironmentUtils]::UnlockConfigSection($Path)
    Write-Host "Config section unlocked"
}

function Get-AppHostConfigPath ($path) {
    if ($path.ToString() -eq [IO.Path]::GetPathRoot($path)) {
        Write-Host "Local applicationhost.config not found, modifying machine-wide config"
        $globalConfigPath = [IO.Path]::Combine($path, "Users", $env:USERNAME, "Documents/IISExpress/config/applicationhost.config")
        if (Test-Path $globalConfigPath) {
            return $globalConfigPath
        }

        throw "No applicationhost.config found in .vs/config anywhere in this directory or its parents, or in ~/Documents/IISExpress/config"    
    }

    $localConfigPath = [IO.Path]::Combine($path, ".vs", "config", "applicationhost.config")
    if (Test-Path $localConfigPath) {
        return $localConfigPath
    }

    return Get-AppHostConfigPath -path (Get-Item $path).Parent.FullName
}