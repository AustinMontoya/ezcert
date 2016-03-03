Add-Type -Path 'ezcert.util.dll'

function Unlock-AppHostSecuritySection {
    Param(
        [string]$Path
    )

    if (!$Path) {
        Write-Host "Searching for applicationhost.config..."
        $Path = Get-AppHostConfigPath
    }

    Write-Host "Modifying $Path"
    [ezcert.util.EnvironmentUtils]::UnlockConfigSection($Path)
    Write-Host "Config section unlocked"
}

function Get-AppHostConfigPath {
    $path = Get-ConfigPath -path (Get-Item -Path $PWD) -targetPath ".vs/config/applicationhost.config"

    if ($path) { return $path }
   
    Write-Host "Local applicationhost.config not found, modifying machine-wide config"
    $globalConfigPath = [IO.Path]::Combine($env:USERPROFILE, "Documents/IISExpress/config/applicationhost.config")
    if (Test-Path $globalConfigPath) {
        return $globalConfigPath
    } 
          
    throw "No applicationhost.config found in .vs/config anywhere in this directory or its parents, or in ~/Documents/IISExpress/config"    
}

function Get-ConfigPath($path, $targetPath) {
    if ($path.ToString() -eq [IO.Path]::GetPathRoot($path)) {
        return $null
    }

    $localConfigPath = [IO.Path]::Combine($path, $targetPath)
    if (Test-Path $localConfigPath) {
        return $localConfigPath
    }

    return Get-ConfigPath -path (Get-Item $path).Parent.FullName -targetPath $targetPath
}