function Unlock-AppHostSecuritySection {
    Param(
        [string]$Path
    )

    if (!$Path) {
        Write-Log "Searching for applicationhost.config..."
        $Path = Get-AppHostConfigPath
    }

    Write-Log "Modifying $Path"
    & $ezcertExecutablePath UnlockConfigSection -configPath="$Path"
    Write-Success "Config section unlocked"
}

function Get-AppHostConfigPath {
    $path = Get-ConfigPath -path (Get-Item -Path $PWD) -targetPath ".vs/config/applicationhost.config"

    if ($path) { return $path }
   
    Write-Info "Local applicationhost.config not found, modifying machine-wide config"
    $globalConfigPath = [IO.Path]::Combine($env:USERPROFILE, "Documents/IISExpress/config/applicationhost.config")
    if (Test-Path $globalConfigPath) {
        return $globalConfigPath
    } 
          
    throw "No applicationhost.config found in .vs/config anywhere in this directory or its parents, or in ~/Documents/IISExpress/config"    
}
